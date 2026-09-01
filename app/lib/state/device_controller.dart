import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ble/ble_connection.dart';
import '../ble/ble_device.dart';
import '../protocol/elk_bledom_codec.dart';
import '../protocol/status_parser.dart';
import 'debouncer.dart';
import 'led_preset.dart';
import 'led_state.dart';
import 'prefs.dart';

/// Единый источник правды для экрана управления **одним** устройством:
/// соединение + состояние ленты. Приложение может держать несколько
/// экземпляров одновременно — по одному на каждое подключённое устройство
/// (см. `DevicesManager`) — поэтому [id] задаётся один раз при создании и не
/// меняется, а всё, что сохраняется в [Prefs], пишется под этим id.
///
/// Интерфейс обновляется оптимистично, команды в BLE уходят с ограничением
/// частоты ([Debouncer]) — чтобы перетаскивание ползунков не забивало канал.
class DeviceController extends ChangeNotifier {
  DeviceController(this._prefs, {required this.id, String? name})
      : _name = name ?? '' {
    final restored = _prefs.deviceStateRaw(id);
    if (restored != null) {
      _led = LedState.tryDecode(restored) ?? const LedState();
    }
    _presets = _prefs.presetsRaw
        .map(LedPreset.decode)
        .whereType<LedPreset>()
        .toList();
  }

  final Prefs _prefs;

  /// Стабильный идентификатор BLE-устройства (адрес/UUID) — не меняется
  /// на протяжении жизни контроллера.
  final String id;

  ElkConnection? _conn;
  StreamSubscription<LinkState>? _stateSub;
  StreamSubscription<ElkStatus>? _statusSub;

  String _name;
  LinkState _linkState = LinkState.disconnected;
  LedState _led = const LedState();
  List<LedPreset> _presets = const [];
  DateTime _lastUserAction = DateTime.fromMillisecondsSinceEpoch(0);

  final _colorDebounce = Debouncer(const Duration(milliseconds: 70));
  final _brightnessDebounce = Debouncer(const Duration(milliseconds: 70));
  final _whiteDebounce = Debouncer(const Duration(milliseconds: 70));
  final _speedDebounce = Debouncer(const Duration(milliseconds: 90));
  final _saveDebounce = Debouncer(const Duration(milliseconds: 400));

  /// Отображаемое имя устройства (из скана или из списка «Мои устройства»).
  String get name => _name.isEmpty ? 'Без имени' : _name;
  LinkState get linkState => _linkState;
  LedState get led => _led;
  bool get isConnected => _linkState == LinkState.connected;
  bool get isBusy =>
      _linkState == LinkState.connecting ||
      _linkState == LinkState.discovering ||
      _linkState == LinkState.reconnecting;

  List<LedPreset> get presets => List.unmodifiable(_presets);

  // ─────────────────────────────── соединение ───────────────────────────────

  Future<void> connectTo(DiscoveredDevice device) =>
      connect(name: device.displayName);

  Future<void> connect({String? name}) async {
    if (name != null && name.isNotEmpty) _name = name;
    if (isConnected) return;
    await _teardownConnection();

    _linkState = LinkState.connecting;
    notifyListeners();

    final conn = ElkConnection(id);
    _conn = conn;
    _stateSub = conn.stateStream.listen(_onLinkState);
    _statusSub = conn.statusStream.listen(_onStatus);

    await _prefs.touchKnownDevice(id, this.name);
    await conn.connect();
  }

  Future<void> reconnect() => connect();

  Future<void> disconnect() async {
    await _teardownConnection();
    _linkState = LinkState.disconnected;
    notifyListeners();
  }

  Future<void> forget() async {
    await disconnect();
    await _prefs.removeKnownDevice(id);
  }

  Future<void> _teardownConnection() async {
    await _stateSub?.cancel();
    await _statusSub?.cancel();
    _stateSub = null;
    _statusSub = null;
    final old = _conn;
    _conn = null;
    await old?.dispose();
  }

  void _onLinkState(LinkState s) {
    _linkState = s;
    if (s == LinkState.connected) {
      // Синхронизируем часы (нужно для таймеров) и выравниваем ленту
      // под текущее состояние интерфейса.
      unawaited(_conn?.sendFrame(ElkBledomCodec.syncTime(DateTime.now())));
      _pushFullState();
    }
    notifyListeners();
  }

  void _onStatus(ElkStatus st) {
    // Подмешиваем состояние от контроллера, только если пользователь
    // не крутил ручки последние 1.5 с — иначе интерфейс будет «дёргаться».
    if (DateTime.now().difference(_lastUserAction).inMilliseconds < 1500) return;
    var next = _led;
    if (st.power != null) next = next.copyWith(power: st.power);
    final r = st.r, g = st.g, b = st.b;
    if (_led.mode == LedMode.color &&
        r != null &&
        g != null &&
        b != null &&
        (r | g | b) != 0) {
      next = next.copyWith(color: Color.fromARGB(255, r, g, b));
    }
    if (st.brightness != null && st.brightness! > 0) {
      next = next.copyWith(brightness: st.brightness);
    }
    if (next != _led) {
      _led = next;
      notifyListeners();
    }
  }

  // ──────────────────────────────── команды ────────────────────────────────

  void _touch() {
    _lastUserAction = DateTime.now();
    _saveDebounce(() => _prefs.setDeviceStateRaw(id, _led.encode()));
  }

  Future<void> _send(Uint8List frame) async {
    await _conn?.sendFrame(frame);
  }

  void setPower(bool on) {
    _touch();
    _led = _led.copyWith(power: on);
    notifyListeners();
    _send(ElkBledomCodec.power(on));
    if (on) _pushActiveChannel();
  }

  void togglePower() => setPower(!_led.power);

  void setColor(Color color, {bool commit = false}) {
    _touch();
    _led = _led.copyWith(color: color, mode: LedMode.color, clearEffect: true);
    notifyListeners();
    void run() => _sendColor();
    if (commit) {
      _colorDebounce.flushNow();
      run();
    } else {
      _colorDebounce(run);
    }
  }

  void setBrightness(int percent, {bool commit = false}) {
    _touch();
    _led = _led.copyWith(brightness: percent.clamp(0, 100));
    notifyListeners();
    // Яркость — единственный рычаг затемнения: регистр `7E 00 01 XX`.
    // Цвет при этом уходит на полной величине (см. [_sendColor]).
    void run() => _send(ElkBledomCodec.brightness(_led.brightness));

    if (commit) {
      _brightnessDebounce.flushNow();
      run();
    } else {
      _brightnessDebounce(run);
    }
  }

  void setWhite(int warm, {bool commit = false}) {
    _touch();
    _led = _led.copyWith(warm: warm.clamp(0, 100), mode: LedMode.white,
        clearEffect: true);
    notifyListeners();
    void run() => _send(ElkBledomCodec.white(_led.warm));
    if (commit) {
      _whiteDebounce.flushNow();
      run();
    } else {
      _whiteDebounce(run);
    }
  }

  void setMode(LedMode mode) {
    if (_led.mode == mode) return;
    _touch();
    _led = _led.copyWith(mode: mode);
    notifyListeners();
    _pushActiveChannel();
  }

  void selectEffect(int id) {
    _touch();
    _led = _led.copyWith(mode: LedMode.effect, effectId: id);
    notifyListeners();
    _send(ElkBledomCodec.effect(id));
    _send(ElkBledomCodec.effectSpeed(_led.effectSpeed));
  }

  void setEffectSpeed(int percent, {bool commit = false}) {
    _touch();
    _led = _led.copyWith(effectSpeed: percent.clamp(0, 100));
    notifyListeners();
    void run() => _send(ElkBledomCodec.effectSpeed(_led.effectSpeed));
    if (commit) {
      _speedDebounce.flushNow();
      run();
    } else {
      _speedDebounce(run);
    }
  }

  // ──────────────────────────────── пресеты ────────────────────────────────

  /// Сохранить текущий режим/цвет/яркость/эффект как новый пресет.
  Future<void> saveCurrentAsPreset(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final preset = LedPreset(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: trimmed,
      state: _led,
    );
    _presets = [..._presets, preset];
    notifyListeners();
    await _persistPresets();
  }

  Future<void> deletePreset(String id) async {
    final next = _presets.where((p) => p.id != id).toList();
    if (next.length == _presets.length) return;
    _presets = next;
    notifyListeners();
    await _persistPresets();
  }

  Future<void> renamePreset(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _presets = [
      for (final p in _presets) p.id == id ? p.copyWith(name: trimmed) : p,
    ];
    notifyListeners();
    await _persistPresets();
  }

  /// Применить пресет: переносит режим/цвет/яркость/эффект (питание не
  /// трогаем) и, если лента включена, сразу шлёт команды на контроллер.
  void applyPreset(LedPreset preset) => applyLedState(preset.state);

  /// Как [applyPreset], но принимает состояние напрямую — используется
  /// сценами, где на разных устройствах применяются разные состояния
  /// одним действием (см. `DevicesManager.applyScene`).
  void applyLedState(LedState s) {
    _touch();
    _led = _led.copyWith(
      color: s.color,
      brightness: s.brightness,
      mode: s.mode,
      warm: s.warm,
      effectId: s.effectId,
      clearEffect: s.effectId == null,
      effectSpeed: s.effectSpeed,
    );
    notifyListeners();
    if (_led.power) {
      _send(ElkBledomCodec.brightness(_led.brightness));
      _pushActiveChannel();
    }
  }

  Future<void> _persistPresets() =>
      _prefs.setPresetsRaw(_presets.map((p) => p.encode()).toList());

  /// Экспорт всех пресетов одной JSON-строкой (для копирования/передачи).
  String exportPresetsJson() =>
      jsonEncode(_presets.map((p) => p.toJson()).toList());

  /// Импортирует пресеты из JSON, произведённого [exportPresetsJson].
  ///
  /// Пресеты с уже занятым id получают новый id (чтобы не перезаписать
  /// существующие), битые записи пропускаются. Возвращает число добавленных
  /// пресетов.
  Future<int> importPresetsJson(String raw) async {
    final List<dynamic> list;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return 0;
      list = decoded;
    } catch (_) {
      return 0;
    }

    final existingIds = _presets.map((p) => p.id).toSet();
    final imported = <LedPreset>[];
    for (final item in list) {
      if (item is! Map) continue;
      final preset = LedPreset.fromJson(item.cast<String, dynamic>());
      if (preset == null) continue;
      var next = preset;
      while (existingIds.contains(next.id)) {
        next = LedPreset(
          id: '${next.id}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
          name: next.name,
          state: next.state,
        );
      }
      existingIds.add(next.id);
      imported.add(next);
    }
    if (imported.isEmpty) return 0;

    _presets = [..._presets, ...imported];
    notifyListeners();
    await _persistPresets();
    return imported.length;
  }

  /// Переслать ленте всё текущее состояние (после подключения).
  void _pushFullState() {
    _send(ElkBledomCodec.power(_led.power));
    if (!_led.power) return;
    _pushActiveChannel();
    _send(ElkBledomCodec.brightness(_led.brightness));
  }

  /// Отправить команду активного режима (цвет / белый / эффект).
  void _pushActiveChannel() {
    switch (_led.mode) {
      case LedMode.color:
        _sendColor();
      case LedMode.white:
        _send(ElkBledomCodec.white(_led.warm));
      case LedMode.effect:
        final id = _led.effectId;
        if (id != null) {
          _send(ElkBledomCodec.effect(id));
          _send(ElkBledomCodec.effectSpeed(_led.effectSpeed));
        }
    }
  }

  /// Цвет уходит на полной величине; затемнение делает регистр яркости
  /// (`ElkBledomCodec.brightness`). Раньше здесь было ещё и умножение RGB на
  /// `brightness/100`, из-за чего на прошивках, честно применяющих регистр,
  /// затемнение получалось квадратичным (50 % ⇒ ≈25 %).
  void _sendColor() {
    final c = _led.color;
    _send(ElkBledomCodec.color(
      (c.r * 255).round(),
      (c.g * 255).round(),
      (c.b * 255).round(),
    ));
  }

  @override
  void dispose() {
    _colorDebounce.dispose();
    _brightnessDebounce.dispose();
    _whiteDebounce.dispose();
    _speedDebounce.dispose();
    _saveDebounce.flushNow();
    _saveDebounce.dispose();
    unawaited(_teardownConnection());
    super.dispose();
  }
}
