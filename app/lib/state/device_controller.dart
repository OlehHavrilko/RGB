import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ble/ble_connection.dart';
import '../ble/ble_device.dart';
import '../protocol/elk_bledom_codec.dart';
import '../protocol/status_parser.dart';
import 'debouncer.dart';
import 'led_state.dart';
import 'prefs.dart';

/// Единый источник правды для экрана управления: соединение + состояние ленты.
///
/// Интерфейс обновляется оптимистично, команды в BLE уходят с ограничением
/// частоты ([Debouncer]) — чтобы перетаскивание ползунков не забивало канал.
class DeviceController extends ChangeNotifier {
  DeviceController(this._prefs);

  final Prefs _prefs;

  ElkConnection? _conn;
  StreamSubscription<LinkState>? _stateSub;
  StreamSubscription<ElkStatus>? _statusSub;

  DiscoveredDevice? _device;
  LinkState _linkState = LinkState.disconnected;
  LedState _led = const LedState();
  DateTime _lastUserAction = DateTime.fromMillisecondsSinceEpoch(0);

  final _colorDebounce = Debouncer(const Duration(milliseconds: 70));
  final _brightnessDebounce = Debouncer(const Duration(milliseconds: 70));
  final _whiteDebounce = Debouncer(const Duration(milliseconds: 70));
  final _speedDebounce = Debouncer(const Duration(milliseconds: 90));

  DiscoveredDevice? get device => _device;
  LinkState get linkState => _linkState;
  LedState get led => _led;
  bool get isConnected => _linkState == LinkState.connected;
  bool get isBusy =>
      _linkState == LinkState.connecting ||
      _linkState == LinkState.discovering ||
      _linkState == LinkState.reconnecting;

  String? get lastKnownDeviceName => _prefs.lastDeviceName;
  String? get lastKnownDeviceId => _prefs.lastDeviceId;

  // ─────────────────────────────── соединение ───────────────────────────────

  Future<void> connectTo(DiscoveredDevice device) async {
    if (_device?.id == device.id && isConnected) return;
    await _teardownConnection();

    _device = device;
    _linkState = LinkState.connecting;
    notifyListeners();

    final conn = ElkConnection(device.id);
    _conn = conn;
    _stateSub = conn.stateStream.listen(_onLinkState);
    _statusSub = conn.statusStream.listen(_onStatus);

    await _prefs.setLastDevice(device.id, device.displayName);
    await conn.connect();
  }

  Future<void> reconnect() async {
    final d = _device;
    if (d != null) await connectTo(d);
  }

  Future<void> disconnect() async {
    await _teardownConnection();
    _linkState = LinkState.disconnected;
    notifyListeners();
  }

  Future<void> forget() async {
    await disconnect();
    _device = null;
    await _prefs.clearLastDevice();
    notifyListeners();
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

  void _touch() => _lastUserAction = DateTime.now();

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
    void run() => _sendColorScaled();
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
    void run() {
      _send(ElkBledomCodec.brightness(_led.brightness));
      _pushActiveChannel();
    }

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
        _sendColorScaled();
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

  /// Цвет отправляем уже затемнённым под текущую яркость — так стабильнее
  /// ведут себя разные прошивки ELK-BLEDOM.
  void _sendColorScaled() {
    final c = _led.color;
    final k = _led.brightness / 100.0;
    _send(ElkBledomCodec.color(
      (c.r * 255 * k).round(),
      (c.g * 255 * k).round(),
      (c.b * 255 * k).round(),
    ));
  }

  @override
  void dispose() {
    _colorDebounce.dispose();
    _brightnessDebounce.dispose();
    _whiteDebounce.dispose();
    _speedDebounce.dispose();
    unawaited(_teardownConnection());
    super.dispose();
  }
}
