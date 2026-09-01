import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Будильник-рассвет: в [minuteOfDay] по локальному времени лента плавно
/// включается и в течение [durationMinutes] набирает яркость от минимума до
/// [targetBrightness] — вместо резкого включения на полную.
@immutable
class SunriseAlarm {
  const SunriseAlarm({
    required this.id,
    required this.minuteOfDay,
    this.durationMinutes = 15,
    this.targetBrightness = 80,
    this.enabled = true,
    this.days = allDays,
  });

  /// 1 = понедельник … 7 = воскресенье (как [DateTime.weekday]).
  static const Set<int> allDays = {1, 2, 3, 4, 5, 6, 7};

  /// Яркость, с которой начинается рассвет — не 0, чтобы лента заметно
  /// зажглась в первую же секунду, а не оставалась незаметно тусклой.
  static const int startBrightness = 1;

  final String id;
  final int minuteOfDay; // 0..1439
  final int durationMinutes; // 1..60
  final int targetBrightness; // 1..100
  final bool enabled;
  final Set<int> days;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;
  bool get everyDay => days.length == 7;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  SunriseAlarm copyWith({
    int? minuteOfDay,
    int? durationMinutes,
    int? targetBrightness,
    bool? enabled,
    Set<int>? days,
  }) =>
      SunriseAlarm(
        id: id,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        targetBrightness: targetBrightness ?? this.targetBrightness,
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
      );

  /// Доля прогресса рассвета в момент [now]: `0.0` — только начался,
  /// `1.0` — закончился. `null` — сейчас не время рассвета (в том числе
  /// если будильник выключен) — проверяет и сегодняшнее, и вчерашнее
  /// начало окна, чтобы не терять рассвет, начавшийся до полуночи.
  double? progressAt(DateTime now) {
    if (!enabled || durationMinutes <= 0) return null;
    for (final dayOffset in const [0, -1]) {
      final day =
          DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
      final start = DateTime(day.year, day.month, day.day, hour, minute);
      final end = start.add(Duration(minutes: durationMinutes));
      if (!now.isBefore(start) &&
          now.isBefore(end) &&
          days.contains(start.weekday)) {
        final elapsedMs = now.difference(start).inMilliseconds;
        final totalMs = durationMinutes * Duration.millisecondsPerMinute;
        return (elapsedMs / totalMs).clamp(0.0, 1.0);
      }
    }
    return null;
  }

  /// Яркость, которую нужно выставить при данной [progress] (0.0..1.0).
  int brightnessAt(double progress) =>
      (startBrightness + progress * (targetBrightness - startBrightness))
          .round()
          .clamp(startBrightness, targetBrightness);

  Map<String, dynamic> toJson() => {
        'id': id,
        'min': minuteOfDay,
        'dur': durationMinutes,
        'target': targetBrightness,
        'en': enabled,
        'days': days.toList()..sort(),
      };

  static SunriseAlarm? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    final min = json['min'];
    if (min is! int || min < 0 || min > 1439) return null;
    final rawDays = json['days'];
    final days = rawDays is List
        ? rawDays.whereType<int>().where((d) => d >= 1 && d <= 7).toSet()
        : allDays;
    final dur = json['dur'];
    final target = json['target'];
    return SunriseAlarm(
      id: id,
      minuteOfDay: min,
      durationMinutes: dur is int ? dur.clamp(1, 60) : 15,
      targetBrightness: target is int ? target.clamp(1, 100) : 80,
      enabled: json['en'] is bool ? json['en'] as bool : true,
      days: days.isEmpty ? allDays : days,
    );
  }

  String encode() => jsonEncode(toJson());

  static SunriseAlarm? decode(String raw) {
    try {
      final obj = jsonDecode(raw);
      return obj is Map ? fromJson(obj.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }
}
