import 'dart:async';

import 'package:flutter/foundation.dart';

import 'daily_schedule.dart';
import 'device_controller.dart';
import 'led_state.dart';
import 'prefs.dart';
import 'sunrise_alarm.dart';

/// Локальный планировщик: таймер сна (одноразовое автоотключение),
/// ежедневные расписания включения/выключения и будильники-рассветы.
///
/// Работает, пока приложение запущено. Срабатывания, пропущенные при
/// закрытом приложении, не навёрстываются (кроме истёкшего таймера сна —
/// он применяется при следующем запуске).
class ScheduleController extends ChangeNotifier {
  ScheduleController(
    this._prefs,
    this._device, {
    Duration tick = const Duration(seconds: 10),
  }) {
    final ms = _prefs.sleepAtEpochMs(_device.id);
    _sleepAt = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    _schedules = _prefs.schedulesRaw(_device.id)
        .map(DailySchedule.decode)
        .whereType<DailySchedule>()
        .toList()
      ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    _sunriseAlarms = _prefs.sunriseAlarmsRaw(_device.id)
        .map(SunriseAlarm.decode)
        .whereType<SunriseAlarm>()
        .toList()
      ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    _lastTick = DateTime.now();
    _timer = Timer.periodic(tick, (_) => _onTick());
    _onTick(); // догнать истёкший таймер сна сразу после запуска
  }

  final Prefs _prefs;
  final DeviceController _device;

  Timer? _timer;
  DateTime _lastTick = DateTime.now();
  DateTime? _sleepAt;
  List<DailySchedule> _schedules = const [];
  List<SunriseAlarm> _sunriseAlarms = const [];

  /// id рассветов, для которых уже отправлена начальная команда
  /// включения в текущем окне — чтобы не слать её на каждый тик.
  final Set<String> _activeSunrises = {};

  // ─────────────────────────────── таймер сна ──────────────────────────────

  bool get sleepActive => _sleepAt != null;
  DateTime? get sleepAt => _sleepAt;

  Duration? get sleepRemaining {
    final s = _sleepAt;
    if (s == null) return null;
    final r = s.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  void startSleep(Duration after) {
    _sleepAt = DateTime.now().add(after);
    _prefs.setSleepAtEpochMs(_device.id, _sleepAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  void cancelSleep() {
    if (_sleepAt == null) return;
    _sleepAt = null;
    _prefs.setSleepAtEpochMs(_device.id, null);
    notifyListeners();
  }

  // ─────────────────────────────── расписание ──────────────────────────────

  List<DailySchedule> get schedules => List.unmodifiable(_schedules);

  Future<void> addSchedule({
    required int minuteOfDay,
    required bool turnOn,
  }) async {
    final sch = DailySchedule(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      minuteOfDay: minuteOfDay.clamp(0, 1439),
      turnOn: turnOn,
    );
    _schedules = [..._schedules, sch]
      ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    notifyListeners();
    await _persist();
  }

  Future<void> updateSchedule(DailySchedule updated) async {
    _schedules = [
      for (final s in _schedules) s.id == updated.id ? updated : s,
    ]..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    notifyListeners();
    await _persist();
  }

  Future<void> toggleSchedule(String id) async {
    DailySchedule? target;
    for (final s in _schedules) {
      if (s.id == id) target = s;
    }
    if (target == null) return;
    await updateSchedule(target.copyWith(enabled: !target.enabled));
  }

  Future<void> deleteSchedule(String id) async {
    final next = _schedules.where((s) => s.id != id).toList();
    if (next.length == _schedules.length) return;
    _schedules = next;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() =>
      _prefs.setSchedulesRaw(_device.id, _schedules.map((s) => s.encode()).toList());

  // ───────────────────────────── будильник-рассвет ─────────────────────────

  List<SunriseAlarm> get sunriseAlarms => List.unmodifiable(_sunriseAlarms);

  Future<void> addSunriseAlarm({
    required int minuteOfDay,
    int durationMinutes = 15,
    int targetBrightness = 80,
  }) async {
    final alarm = SunriseAlarm(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      minuteOfDay: minuteOfDay.clamp(0, 1439),
      durationMinutes: durationMinutes,
      targetBrightness: targetBrightness,
    );
    _sunriseAlarms = [..._sunriseAlarms, alarm]
      ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    notifyListeners();
    await _persistSunriseAlarms();
  }

  Future<void> updateSunriseAlarm(SunriseAlarm updated) async {
    _sunriseAlarms = [
      for (final a in _sunriseAlarms) a.id == updated.id ? updated : a,
    ]..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    notifyListeners();
    await _persistSunriseAlarms();
  }

  Future<void> toggleSunriseAlarm(String id) async {
    SunriseAlarm? target;
    for (final a in _sunriseAlarms) {
      if (a.id == id) target = a;
    }
    if (target == null) return;
    await updateSunriseAlarm(target.copyWith(enabled: !target.enabled));
  }

  Future<void> deleteSunriseAlarm(String id) async {
    final next = _sunriseAlarms.where((a) => a.id != id).toList();
    if (next.length == _sunriseAlarms.length) return;
    _sunriseAlarms = next;
    _activeSunrises.remove(id);
    notifyListeners();
    await _persistSunriseAlarms();
  }

  Future<void> _persistSunriseAlarms() => _prefs.setSunriseAlarmsRaw(
      _device.id, _sunriseAlarms.map((a) => a.encode()).toList());

  // ──────────────────────────────────── тик ────────────────────────────────

  void _onTick() {
    final now = DateTime.now();
    final prev = _lastTick;
    _lastTick = now;

    final s = _sleepAt;
    if (s != null && !now.isBefore(s)) {
      _sleepAt = null;
      _prefs.setSleepAtEpochMs(_device.id, null);
      _device.setPower(false);
      notifyListeners();
    }

    for (final sch in _schedules) {
      if (sch.firesBetween(prev, now)) {
        _device.setPower(sch.turnOn);
      }
    }

    for (final alarm in _sunriseAlarms) {
      final progress = alarm.progressAt(now);
      if (progress == null) {
        _activeSunrises.remove(alarm.id);
        continue;
      }
      if (_activeSunrises.add(alarm.id)) {
        // Начало окна рассвета: один раз включаем ленту в тёплом белом —
        // дальше на каждый тик только поднимаем яркость.
        _device.setMode(LedMode.white);
        _device.setWhite(80);
        _device.setPower(true);
      }
      _device.setBrightness(alarm.brightnessAt(progress), commit: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
