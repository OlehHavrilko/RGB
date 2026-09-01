import 'package:flutter/foundation.dart';

import '../ble/ble_device.dart';
import 'device_controller.dart';
import 'known_device.dart';
import 'prefs.dart';
import 'schedule_controller.dart';

/// Держит по одной паре [DeviceController]/[ScheduleController] на каждое
/// устройство, с которым приложение когда-либо соединялось, и позволяет
/// подключаться к нескольким лентам одновременно — каждая со своим BLE-
/// соединением, состоянием, таймером сна и расписанием.
///
/// Библиотека пользовательских пресетов при этом общая на все устройства
/// (см. [Prefs.presetsRaw]) — сохранённый на одной ленте пресет можно
/// применить на любой другой.
class DevicesManager extends ChangeNotifier {
  DevicesManager(this._prefs) {
    for (final known in _prefs.knownDevices) {
      _ensureSession(known.id, name: known.name);
    }
  }

  final Prefs _prefs;
  final Map<String, DeviceController> _controllers = {};
  final Map<String, ScheduleController> _schedules = {};
  bool _syncEnabled = false;

  /// Известные устройства (когда-либо подключались), последнее — первым.
  List<KnownDevice> get knownDevices => _prefs.knownDevices;

  /// Режим синхронизации: пока включён, действие на одном устройстве
  /// (см. [broadcastFrom]) зеркалится на все остальные подключённые.
  /// Хранится только в памяти — сбрасывается при перезапуске приложения.
  bool get syncEnabled => _syncEnabled;

  void setSyncEnabled(bool value) {
    if (_syncEnabled == value) return;
    _syncEnabled = value;
    notifyListeners();
  }

  /// Активные сессии — по одной на каждое известное устройство, независимо
  /// от того, подключены они сейчас или нет.
  List<DeviceController> get sessions =>
      List.unmodifiable(knownDevices.map((d) => _ensureSession(d.id, name: d.name)));

  List<DeviceController> get connectedSessions =>
      sessions.where((s) => s.isConnected).toList();

  DeviceController controllerFor(String id, {String? name}) =>
      _ensureSession(id, name: name);

  ScheduleController scheduleFor(String id, {String? name}) {
    _ensureSession(id, name: name);
    return _schedules[id]!;
  }

  DeviceController _ensureSession(String id, {String? name}) {
    final existing = _controllers[id];
    if (existing != null) return existing;
    final ctrl = DeviceController(_prefs, id: id, name: name);
    _controllers[id] = ctrl;
    _schedules[id] = ScheduleController(_prefs, ctrl);
    ctrl.addListener(notifyListeners);
    return ctrl;
  }

  /// Подключиться к устройству, найденному сканером (создаёт сессию, если
  /// это первое подключение к нему).
  Future<void> connect(DiscoveredDevice device) async {
    final ctrl = _ensureSession(device.id, name: device.name);
    await ctrl.connectTo(device);
    notifyListeners();
  }

  /// Переподключиться к уже известному устройству по id (без скана).
  Future<void> connectKnown(String id) async {
    final ctrl = _ensureSession(id);
    await ctrl.connect();
    notifyListeners();
  }

  /// Если включён [syncEnabled], применяет [action] ко всем подключённым
  /// устройствам, кроме [origin] (действие на самом [origin] вызывающий
  /// код выполняет отдельно, до или после этого вызова). Ничего не делает,
  /// если синхронизация выключена или подключено меньше двух устройств.
  void broadcastFrom(
    DeviceController origin,
    void Function(DeviceController target) action,
  ) {
    if (!_syncEnabled) return;
    for (final other in connectedSessions) {
      if (other.id != origin.id) action(other);
    }
  }

  /// Отключиться и полностью забыть устройство: рвём соединение, удаляем
  /// его сохранённое состояние/расписание и закрываем контроллеры.
  Future<void> forget(String id) async {
    final ctrl = _controllers.remove(id);
    final sched = _schedules.remove(id);
    if (ctrl != null) {
      ctrl.removeListener(notifyListeners);
      await ctrl.forget();
      ctrl.dispose();
    } else {
      await _prefs.removeKnownDevice(id);
    }
    sched?.dispose();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.removeListener(notifyListeners);
      ctrl.dispose();
    }
    for (final sched in _schedules.values) {
      sched.dispose();
    }
    super.dispose();
  }
}
