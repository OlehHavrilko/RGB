import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Фон приложения: глубокий тёмный градиент с мягким цветным свечением,
/// которое плавно перетекает вслед за текущим цветом ленты.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.glow,
    required this.child,
    this.intensity = 1,
  });

  /// Цвет свечения (обычно `LedState.displayColor`).
  final Color glow;

  /// 0 — свечение погашено (лента выключена), 1 — обычная яркость.
  final double intensity;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: glow),
      duration: Motion.slow,
      curve: Motion.standard,
      builder: (context, animatedGlow, _) {
        final g = animatedGlow ?? glow;
        return AnimatedContainer(
          duration: Motion.slow,
          curve: Motion.standard,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.75),
              radius: 1.35,
              colors: [
                Color.lerp(AppColors.bg, g, 0.22 * intensity)!,
                AppColors.bg,
                const Color(0xFF030305),
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -120,
                bottom: -160,
                child: _Blob(color: g.withValues(alpha: 0.16 * intensity)),
              ),
              Positioned(
                right: -140,
                top: -120,
                child: _Blob(
                  color: AppColors.accent.withValues(alpha: 0.10 * intensity),
                  size: 320,
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, this.size = 380});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 160, spreadRadius: 80)],
        ),
      ),
    );
  }
}
