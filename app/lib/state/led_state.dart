import 'dart:convert';

import 'package:flutter/material.dart';

/// Активный режим вывода ленты.
enum LedMode { color, white, effect }

int _clampInt(Object? v, int lo, int hi, int fallback) {
  if (v is int) return v.clamp(lo, hi);
  if (v is num) return v.round().clamp(lo, hi);
  return fallback;
}

/// Полное состояние ленты, отражаемое интерфейсом.
///
/// [color] хранит «чистый» цвет на полной яркости; фактическая яркость
/// применяется отдельно через [brightness] (и дублируется затемнением RGB
/// при отправке — так надёжнее работает на разных прошивках).
@immutable
class LedState {
  const LedState({
    this.power = false,
    this.color = const Color(0xFF2F7BFF),
    this.brightness = 100,
    this.mode = LedMode.color,
    this.warm = 60,
    this.effectId,
    this.effectSpeed = 50,
  });

  final bool power;
  final Color color;
  final int brightness; // 0..100
  final LedMode mode;
  final int warm; // 0..100, только для LedMode.white
  final int? effectId;
  final int effectSpeed; // 0..100

  LedState copyWith({
    bool? power,
    Color? color,
    int? brightness,
    LedMode? mode,
    int? warm,
    int? effectId,
    bool clearEffect = false,
    int? effectSpeed,
  }) {
    return LedState(
      power: power ?? this.power,
      color: color ?? this.color,
      brightness: brightness ?? this.brightness,
      mode: mode ?? this.mode,
      warm: warm ?? this.warm,
      effectId: clearEffect ? null : (effectId ?? this.effectId),
      effectSpeed: effectSpeed ?? this.effectSpeed,
    );
  }

  /// Цвет с учётом текущей яркости — для свечения и превью в интерфейсе.
  Color get displayColor {
    if (mode == LedMode.white) {
      // Тёплый (255,180,107) <-> холодный (201,226,255).
      final t = warm / 100.0;
      final c = Color.lerp(
        const Color(0xFFC9E2FF),
        const Color(0xFFFFB46B),
        t,
      )!;
      return Color.fromARGB(
        255,
        (c.r * 255 * brightness / 100).round(),
        (c.g * 255 * brightness / 100).round(),
        (c.b * 255 * brightness / 100).round(),
      );
    }
    return Color.fromARGB(
      255,
      (color.r * 255 * brightness / 100).round(),
      (color.g * 255 * brightness / 100).round(),
      (color.b * 255 * brightness / 100).round(),
    );
  }

  // ─────────────────────────────── сериализация ────────────────────────────
  //
  // Используется и для пользовательских пресетов, и для «запомнить последний
  // режим». Разбор устойчив к битым/отсутствующим полям — любое из них
  // откатывается к значению по умолчанию.

  Map<String, dynamic> toJson() => {
        'power': power,
        'color': color.toARGB32(),
        'brightness': brightness,
        'mode': mode.name,
        'warm': warm,
        'effectId': effectId,
        'effectSpeed': effectSpeed,
      };

  factory LedState.fromJson(Map<String, dynamic> json) {
    const fallback = LedState();
    final mode = LedMode.values.firstWhere(
      (m) => m.name == json['mode'],
      orElse: () => fallback.mode,
    );
    final rawColor = json['color'];
    final color =
        rawColor is int ? Color(rawColor | 0xFF000000) : fallback.color;
    final rawEffect = json['effectId'];
    final effectId = rawEffect is int ? rawEffect & 0xFF : null;
    return LedState(
      power: json['power'] is bool ? json['power'] as bool : fallback.power,
      color: color,
      brightness: _clampInt(json['brightness'], 0, 100, fallback.brightness),
      mode: mode,
      warm: _clampInt(json['warm'], 0, 100, fallback.warm),
      effectId: effectId,
      effectSpeed: _clampInt(json['effectSpeed'], 0, 100, fallback.effectSpeed),
    );
  }

  String encode() => jsonEncode(toJson());

  static LedState? tryDecode(String raw) {
    try {
      final obj = jsonDecode(raw);
      return obj is Map ? LedState.fromJson(obj.cast<String, dynamic>()) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is LedState &&
      other.power == power &&
      other.color == color &&
      other.brightness == brightness &&
      other.mode == mode &&
      other.warm == warm &&
      other.effectId == effectId &&
      other.effectSpeed == effectSpeed;

  @override
  int get hashCode =>
      Object.hash(power, color, brightness, mode, warm, effectId, effectSpeed);
}
