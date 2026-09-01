import 'package:chromify/state/sunrise_alarm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SunriseAlarm сериализация', () {
    test('round-trip через encode/decode', () {
      const alarm = SunriseAlarm(
        id: 'a1',
        minuteOfDay: 6 * 60 + 30,
        durationMinutes: 20,
        targetBrightness: 70,
        days: {1, 2, 3, 4, 5},
      );
      final restored = SunriseAlarm.decode(alarm.encode());
      expect(restored, isNotNull);
      expect(restored!.id, 'a1');
      expect(restored.minuteOfDay, 390);
      expect(restored.durationMinutes, 20);
      expect(restored.targetBrightness, 70);
      expect(restored.days, {1, 2, 3, 4, 5});
    });

    test('fromJson подставляет умолчания для битых/отсутствующих полей', () {
      final restored = SunriseAlarm.fromJson({'id': 'x', 'min': 100});
      expect(restored, isNotNull);
      expect(restored!.durationMinutes, 15);
      expect(restored.targetBrightness, 80);
      expect(restored.days, SunriseAlarm.allDays);
      expect(restored.enabled, isTrue);
    });

    test('fromJson отклоняет запись без id/min', () {
      expect(SunriseAlarm.fromJson({'min': 10}), isNull);
      expect(SunriseAlarm.fromJson({'id': 'x', 'min': 9999}), isNull);
    });

    test('decode на мусоре возвращает null', () {
      expect(SunriseAlarm.decode('{'), isNull);
      expect(SunriseAlarm.decode('[]'), isNull);
    });
  });

  group('SunriseAlarm.progressAt', () {
    const alarm = SunriseAlarm(
      id: 'a1',
      minuteOfDay: 7 * 60, // 07:00
      durationMinutes: 20,
    );

    test('null до начала окна', () {
      final before = DateTime(2026, 1, 5, 6, 59, 59); // понедельник
      expect(alarm.progressAt(before), isNull);
    });

    test('0.0 в момент начала', () {
      final start = DateTime(2026, 1, 5, 7, 0);
      expect(alarm.progressAt(start), 0.0);
    });

    test('0.5 в середине окна', () {
      final mid = DateTime(2026, 1, 5, 7, 10);
      expect(alarm.progressAt(mid), closeTo(0.5, 0.001));
    });

    test('null сразу после окончания окна', () {
      final after = DateTime(2026, 1, 5, 7, 20);
      expect(alarm.progressAt(after), isNull);
    });

    test('null в выключенном состоянии', () {
      final disabled = alarm.copyWith(enabled: false);
      expect(disabled.progressAt(DateTime(2026, 1, 5, 7, 5)), isNull);
    });

    test('null в день, не входящий в days', () {
      final weekdayOnly = alarm.copyWith(days: {1, 2, 3, 4, 5});
      final saturday = DateTime(2026, 1, 10, 7, 5); // суббота
      expect(weekdayOnly.progressAt(saturday), isNull);
    });

    test('окно, начавшееся вчера вечером, распознаётся после полуночи', () {
      const lateAlarm = SunriseAlarm(
        id: 'a2',
        minuteOfDay: 23 * 60 + 50, // 23:50
        durationMinutes: 30,
      );
      final afterMidnight = DateTime(2026, 1, 6, 0, 5); // вторник, 00:05
      final progress = lateAlarm.progressAt(afterMidnight);
      expect(progress, isNotNull);
      expect(progress, closeTo(0.5, 0.01));
    });
  });

  group('SunriseAlarm.brightnessAt', () {
    const alarm = SunriseAlarm(id: 'a1', minuteOfDay: 0, targetBrightness: 80);

    test('минимум в начале, цель в конце', () {
      expect(alarm.brightnessAt(0.0), SunriseAlarm.startBrightness);
      expect(alarm.brightnessAt(1.0), 80);
    });

    test('монотонно растёт с прогрессом', () {
      expect(alarm.brightnessAt(0.5), greaterThan(alarm.brightnessAt(0.25)));
    });
  });
}
