import 'package:flutter/animation.dart';

/// Токены движения — единые длительности и кривые для всех анимаций.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 640);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutQuint;
  static const Curve press = Curves.easeOut;
  static const Curve spring = Curves.easeOutBack;
}
