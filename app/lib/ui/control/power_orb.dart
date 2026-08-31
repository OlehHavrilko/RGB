import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/pressable.dart';

/// Крупная кнопка питания. Во включённом состоянии светится текущим
/// цветом ленты, в выключенном — гаснет до тёмного стекла.
class PowerOrb extends StatelessWidget {
  const PowerOrb({
    super.key,
    required this.on,
    required this.glow,
    required this.onTap,
    this.size = 132,
  });

  final bool on;
  final Color glow;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      borderRadius: BorderRadius.circular(size),
      child: AnimatedContainer(
        duration: Motion.emphasized,
        curve: Motion.emphasizedCurve,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: on
                ? [glow, Color.lerp(glow, Colors.black, 0.35)!]
                : const [AppColors.bgElevated, Color(0xFF0A0A11)],
          ),
          border: Border.all(
            color: on ? Colors.white.withValues(alpha: 0.5) : AppColors.hairline,
            width: 1.5,
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.6),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ]
              : const [],
        ),
        child: Icon(
          Icons.power_settings_new_rounded,
          size: size * 0.36,
          color: on ? Colors.white : AppColors.textFaint,
        ),
      ),
    );
  }
}
