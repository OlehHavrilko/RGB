import 'package:shared_preferences/shared_preferences.dart';

import 'known_device.dart';

/// Тонкая обёртка над [SharedPreferences]: список известных устройств и,
/// для каждого из них по отдельности (ключи с суффиксом `:<id>`) —
/// последнее состояние ленты, таймер сна и расписания. Пресеты — общая
/// библиотека на всё приложение, не привязана к конкретному устройству.
class Prefs {
  Prefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<Prefs> load() async => Prefs(await SharedPreferences.getInstance());

  static const _kKnownDevices = 'known_devices_v1';
  static const _kPresets = 'presets_v1';
  static const _kScenes = 'scenes_v1';
  static const _kDeviceStatePrefix = 'device_state_v1:';
  static const _kSleepAtPrefix = 'sleep_at_epoch_ms:';
  static const _kSchedulesPrefix = 'schedules_v1:';
  static const _kSunriseAlarmsPrefix = 'sunrise_alarms_v1:';
  static const _kLocale = 'locale_v1';

  // ───────────────────────────── известные устройства ──────────────────────

  /// Все устройства, к которым когда-либо подключались, в порядке
  /// «последнее использованное — первым».
  List<KnownDevice> get knownDevices => (_prefs.getStringList(_kKnownDevices) ??
          const <String>[])
      .map(KnownDevice.decode)
      .whereType<KnownDevice>()
      .toList();

  /// Добавляет устройство в начало списка известных (или поднимает его туда,
  /// если оно уже есть) и обновляет отображаемое имя.
  Future<void> touchKnownDevice(String id, String name) async {
    final next = [
      KnownDevice(id: id, name: name),
      ...knownDevices.where((d) => d.id != id),
    ];
    await _prefs.setStringList(
      _kKnownDevices,
      next.map((d) => d.encode()).toList(),
    );
  }

  Future<void> removeKnownDevice(String id) async {
    final next = knownDevices.where((d) => d.id != id).toList();
    await _prefs.setStringList(
      _kKnownDevices,
      next.map((d) => d.encode()).toList(),
    );
    await _prefs.remove('$_kDeviceStatePrefix$id');
    await _prefs.remove('$_kSleepAtPrefix$id');
    await _prefs.remove('$_kSchedulesPrefix$id');
    await _prefs.remove('$_kSunriseAlarmsPrefix$id');
  }

  // ─────────────────────────────── пресеты (общие) ─────────────────────────

  /// Список пресетов, каждый — отдельная JSON-строка.
  List<String> get presetsRaw =>
      _prefs.getStringList(_kPresets) ?? const <String>[];

  Future<void> setPresetsRaw(List<String> raw) =>
      _prefs.setStringList(_kPresets, raw);

  // ─────────────────────────────── сцены (общие) ───────────────────────────

  /// Список сцен — снимков состояний нескольких устройств сразу.
  List<String> get scenesRaw =>
      _prefs.getStringList(_kScenes) ?? const <String>[];

  Future<void> setScenesRaw(List<String> raw) =>
      _prefs.setStringList(_kScenes, raw);

  // ──────────────────────── последнее состояние ленты ──────────────────────

  String? deviceStateRaw(String deviceId) =>
      _prefs.getString('$_kDeviceStatePrefix$deviceId');

  Future<void> setDeviceStateRaw(String deviceId, String raw) =>
      _prefs.setString('$_kDeviceStatePrefix$deviceId', raw);

  // ──────────────────────────── таймер сна ────────────────────────────────

  /// Абсолютное время автоотключения (epoch ms) либо `null`.
  int? sleepAtEpochMs(String deviceId) =>
      _prefs.getInt('$_kSleepAtPrefix$deviceId');

  Future<void> setSleepAtEpochMs(String deviceId, int? value) async {
    final key = '$_kSleepAtPrefix$deviceId';
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setInt(key, value);
    }
  }

  // ─────────────────────────── расписание ─────────────────────────────────

  List<String> schedulesRaw(String deviceId) =>
      _prefs.getStringList('$_kSchedulesPrefix$deviceId') ?? const <String>[];

  Future<void> setSchedulesRaw(String deviceId, List<String> raw) =>
      _prefs.setStringList('$_kSchedulesPrefix$deviceId', raw);

  // ──────────────────────────── будильник-рассвет ──────────────────────────

  List<String> sunriseAlarmsRaw(String deviceId) =>
      _prefs.getStringList('$_kSunriseAlarmsPrefix$deviceId') ??
      const <String>[];

  Future<void> setSunriseAlarmsRaw(String deviceId, List<String> raw) =>
      _prefs.setStringList('$_kSunriseAlarmsPrefix$deviceId', raw);

  // ─────────────────────────── язык интерфейса ─────────────────────────────

  /// Код языка, выбранный пользователем ('ru'/'en'), либо `null`, если
  /// пользователь ничего не выбирал — тогда действует язык системы.
  String? get localeCode => _prefs.getString(_kLocale);

  Future<void> setLocaleCode(String code) => _prefs.setString(_kLocale, code);
}
