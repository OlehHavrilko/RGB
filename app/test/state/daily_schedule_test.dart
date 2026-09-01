import 'package:flutter_test/flutter_test.dart';
import 'package:rgb_controller/state/daily_schedule.dart';

void main() {
  DailySchedule at(int h, int m, {bool on = true, bool enabled = true, Set<int>? days}) =>
      DailySchedule(
        id: 't',
        minuteOfDay: h * 60 + m,
        turnOn: on,
        enabled: enabled,
        days: days ?? DailySchedule.allDays,
      );

  group('DailySchedule.firesBetween', () {
    test('срабатывает, когда момент времени попал в интервал', () {
      final s = at(7, 30);
      final from = DateTime(2026, 9, 1, 7, 29, 55);
      final to = DateTime(2026, 9, 1, 7, 30, 5);
      expect(s.firesBetween(from, to), isTrue);
    });

    test('не срабатывает вне интервала', () {
      final s = at(7, 30);
      final from = DateTime(2026, 9, 1, 7, 30, 1);
      final to = DateTime(2026, 9, 1, 7, 30, 20);
      expect(s.firesBetween(from, to), isFalse);
    });

    test('граница from эксклюзивна, to инклюзивна', () {
      final s = at(7, 30);
      expect(
        s.firesBetween(DateTime(2026, 9, 1, 7, 30), DateTime(2026, 9, 1, 7, 31)),
        isFalse,
        reason: 'ровно from — не считается',
      );
      expect(
        s.firesBetween(DateTime(2026, 9, 1, 7, 29), DateTime(2026, 9, 1, 7, 30)),
        isTrue,
        reason: 'ровно to — считается',
      );
    });

    test('выключенное расписание не срабатывает', () {
      final s = at(7, 30, enabled: false);
      expect(
        s.firesBetween(DateTime(2026, 9, 1, 7, 29), DateTime(2026, 9, 1, 7, 31)),
        isFalse,
      );
    });

    test('срабатывает через полночь (интервал пересекает дату)', () {
      final s = at(0, 0);
      final from = DateTime(2026, 9, 1, 23, 59, 55);
      final to = DateTime(2026, 9, 2, 0, 0, 10);
      expect(s.firesBetween(from, to), isTrue);
    });

    test('учитывает день недели', () {
      // 2026-09-01 — вторник (weekday 2).
      final tueOnly = at(7, 30, days: {2});
      final wedOnly = at(7, 30, days: {3});
      final from = DateTime(2026, 9, 1, 7, 29);
      final to = DateTime(2026, 9, 1, 7, 31);
      expect(tueOnly.firesBetween(from, to), isTrue);
      expect(wedOnly.firesBetween(from, to), isFalse);
    });
  });

  group('DailySchedule сериализация', () {
    test('round-trip', () {
      final s = at(22, 15, on: false, days: {1, 3, 5});
      final decoded = DailySchedule.decode(s.encode());
      expect(decoded, isNotNull);
      expect(decoded!.minuteOfDay, 22 * 60 + 15);
      expect(decoded.turnOn, isFalse);
      expect(decoded.days, {1, 3, 5});
    });

    test('timeLabel форматирует с ведущими нулями', () {
      expect(at(7, 5).timeLabel, '07:05');
      expect(at(23, 0).timeLabel, '23:00');
    });

    test('fromJson отклоняет мусорное время', () {
      expect(DailySchedule.fromJson({'id': 'x', 'min': 5000}), isNull);
      expect(DailySchedule.fromJson({'id': 'x', 'min': -1}), isNull);
      expect(DailySchedule.fromJson({'id': '', 'min': 60}), isNull);
    });

    test('пустой список дней откатывается к «каждый день»', () {
      final s = DailySchedule.fromJson({'id': 'x', 'min': 60, 'days': <int>[]});
      expect(s!.days, DailySchedule.allDays);
    });

    test('decode на мусоре возвращает null', () {
      expect(DailySchedule.decode('nope'), isNull);
      expect(DailySchedule.decode('12'), isNull);
    });
  });
}
