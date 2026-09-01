import 'package:shared_preferences/shared_preferences.dart';

/// Тонкая обёртка над [SharedPreferences]: последнее устройство, список
/// пользовательских пресетов и последнее состояние ленты.
class Prefs {
  Prefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<Prefs> load() async => Prefs(await SharedPreferences.getInstance());

  static const _kLastDeviceId = 'last_device_id';
  static const _kLastDeviceName = 'last_device_name';
  static const _kPresets = 'presets_v1';
  static const _kLastState = 'last_led_state_v1';

  String? get lastDeviceId => _prefs.getString(_kLastDeviceId);
  String? get lastDeviceName => _prefs.getString(_kLastDeviceName);

  Future<void> setLastDevice(String id, String name) async {
    await _prefs.setString(_kLastDeviceId, id);
    await _prefs.setString(_kLastDeviceName, name);
  }

  Future<void> clearLastDevice() async {
    await _prefs.remove(_kLastDeviceId);
    await _prefs.remove(_kLastDeviceName);
  }

  // ─────────────────────────────── пресеты ─────────────────────────────────

  /// Список пресетов, каждый — отдельная JSON-строка.
  List<String> get presetsRaw =>
      _prefs.getStringList(_kPresets) ?? const <String>[];

  Future<void> setPresetsRaw(List<String> raw) =>
      _prefs.setStringList(_kPresets, raw);

  // ──────────────────────── последнее состояние ленты ──────────────────────

  String? get lastStateRaw => _prefs.getString(_kLastState);

  Future<void> setLastStateRaw(String raw) =>
      _prefs.setString(_kLastState, raw);
}
