import 'package:flutter/material.dart';

/// Палитра приложения. Тёмная тема как основная и единственная —
/// подсветка комнаты и без того меняет фон.
abstract final class AppColors {
  static const Color bg = Color(0xFF07070B);
  static const Color bgElevated = Color(0xFF101018);

  /// Стеклянные поверхности — полупрозрачный белый поверх фона.
  static const Color glass = Color(0x14FFFFFF);
  static const Color glassStrong = Color(0x1FFFFFFF);
  static const Color hairline = Color(0x1FFFFFFF);

  static const Color textPrimary = Color(0xFFF4F5F8);
  static const Color textSecondary = Color(0xFF9A9BA7);
  static const Color textFaint = Color(0xFF62636E);

  static const Color accent = Color(0xFF6C7BFF);
  static const Color accentSoft = Color(0xFF9AA4FF);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color success = Color(0xFF3BE38B);

  static const List<Color> scanPulse = [
    Color(0xFF6C7BFF),
    Color(0xFF23E0D4),
  ];
}
