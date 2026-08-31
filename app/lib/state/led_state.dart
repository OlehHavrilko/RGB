import 'package:flutter/material.dart';

/// Активный режим вывода ленты.
enum LedMode { color, white, effect }

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
