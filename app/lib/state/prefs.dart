import 'package:shared_preferences/shared_preferences.dart';

/// Тонкая обёртка над [SharedPreferences] для запоминания последнего устройства.
class Prefs {
  Prefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<Prefs> load() async => Prefs(await SharedPreferences.getInstance());

  static const _kLastDeviceId = 'last_device_id';
  static const _kLastDeviceName = 'last_device_name';

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
}
