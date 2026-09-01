import 'package:chromify/state/device_controller.dart';
import 'package:chromify/state/prefs.dart';
import 'package:chromify/state/schedule_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ScheduleController> _newController() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = Prefs(await SharedPreferences.getInstance());
  final device = DeviceController(prefs, id: 'AA:BB:CC:DD:EE:FF');
  // Тик раз в час — тесты ниже проверяют только CRUD, а не срабатывание
  // по расписанию, так что реальные тики не нужны.
  return ScheduleController(prefs, device, tick: const Duration(hours: 1));
}

void main() {
  group('ScheduleController будильники-рассветы', () {
    test('изначально пусто', () async {
      final sched = await _newController();
      expect(sched.sunriseAlarms, isEmpty);
    });

    test('addSunriseAlarm добавляет и сортирует по времени', () async {
      final sched = await _newController();
      await sched.addSunriseAlarm(minuteOfDay: 8 * 60);
      await sched.addSunriseAlarm(minuteOfDay: 6 * 60);

      expect(sched.sunriseAlarms.map((a) => a.minuteOfDay), [6 * 60, 8 * 60]);
    });

    test('addSunriseAlarm сохраняет длительность и яркость', () async {
      final sched = await _newController();
      await sched.addSunriseAlarm(
        minuteOfDay: 420,
        durationMinutes: 25,
        targetBrightness: 60,
      );

      final alarm = sched.sunriseAlarms.single;
      expect(alarm.durationMinutes, 25);
      expect(alarm.targetBrightness, 60);
      expect(alarm.enabled, isTrue);
    });

    test('toggleSunriseAlarm переключает enabled', () async {
      final sched = await _newController();
      await sched.addSunriseAlarm(minuteOfDay: 420);
      final id = sched.sunriseAlarms.single.id;

      await sched.toggleSunriseAlarm(id);
      expect(sched.sunriseAlarms.single.enabled, isFalse);

      await sched.toggleSunriseAlarm(id);
      expect(sched.sunriseAlarms.single.enabled, isTrue);
    });

    test('updateSunriseAlarm заменяет запись и пересортировывает', () async {
      final sched = await _newController();
      await sched.addSunriseAlarm(minuteOfDay: 420);
      final original = sched.sunriseAlarms.single;

      await sched.updateSunriseAlarm(original.copyWith(minuteOfDay: 300));

      expect(sched.sunriseAlarms.single.minuteOfDay, 300);
      expect(sched.sunriseAlarms.single.id, original.id);
    });

    test('deleteSunriseAlarm убирает запись', () async {
      final sched = await _newController();
      await sched.addSunriseAlarm(minuteOfDay: 420);
      final id = sched.sunriseAlarms.single.id;

      await sched.deleteSunriseAlarm(id);

      expect(sched.sunriseAlarms, isEmpty);
    });

    test('переживает пересоздание из тех же Prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = Prefs(await SharedPreferences.getInstance());
      final device = DeviceController(prefs, id: 'AA:BB');
      final first =
          ScheduleController(prefs, device, tick: const Duration(hours: 1));
      await first.addSunriseAlarm(minuteOfDay: 420, targetBrightness: 55);

      final second =
          ScheduleController(prefs, device, tick: const Duration(hours: 1));
      expect(second.sunriseAlarms.single.targetBrightness, 55);
    });
  });
}
