import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Ежедневное расписание: в [minuteOfDay] по локальному времени включить или
/// выключить ленту, в выбранные дни недели.
@immutable
class DailySchedule {
  const DailySchedule({
    required this.id,
    required this.minuteOfDay,
    required this.turnOn,
    this.enabled = true,
    this.days = allDays,
  });

  /// 1 = понедельник … 7 = воскресенье (как [DateTime.weekday]).
  static const Set<int> allDays = {1, 2, 3, 4, 5, 6, 7};

  final String id;
  final int minuteOfDay; // 0..1439
  final bool turnOn;
  final bool enabled;
  final Set<int> days;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;
  bool get everyDay => days.length == 7;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  DailySchedule copyWith({
    int? minuteOfDay,
    bool? turnOn,
    bool? enabled,
    Set<int>? days,
  }) =>
      DailySchedule(
        id: id,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        turnOn: turnOn ?? this.turnOn,
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
      );

  /// Есть ли момент срабатывания в полуинтервале `(from, to]`.
  /// Тик планировщика короткий, поэтому достаточно перебрать календарные дни
  /// на границах интервала.
  bool firesBetween(DateTime from, DateTime to) {
    if (!enabled || !to.isAfter(from)) return false;
    for (var day = DateTime(from.year, from.month, from.day);
        !day.isAfter(to);
        day = day.add(const Duration(days: 1))) {
      final fire = DateTime(day.year, day.month, day.day, hour, minute);
      if (fire.isAfter(from) &&
          !fire.isAfter(to) &&
          days.contains(fire.weekday)) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'min': minuteOfDay,
        'on': turnOn,
        'en': enabled,
        'days': days.toList()..sort(),
      };

  static DailySchedule? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    final min = json['min'];
    if (min is! int || min < 0 || min > 1439) return null;
    final rawDays = json['days'];
    final days = rawDays is List
        ? rawDays.whereType<int>().where((d) => d >= 1 && d <= 7).toSet()
        : allDays;
    return DailySchedule(
      id: id,
      minuteOfDay: min,
      turnOn: json['on'] is bool ? json['on'] as bool : true,
      enabled: json['en'] is bool ? json['en'] as bool : true,
      days: days.isEmpty ? allDays : days,
    );
  }

  String encode() => jsonEncode(toJson());

  static DailySchedule? decode(String raw) {
    try {
      final obj = jsonDecode(raw);
      return obj is Map ? fromJson(obj.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }
}
