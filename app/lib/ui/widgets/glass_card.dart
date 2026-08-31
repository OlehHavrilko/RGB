import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Полупрозрачная «стеклянная» карточка с размытием фона и тонкой обводкой.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 26,
    this.strong = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: strong ? AppColors.glassStrong : AppColors.glass,
            borderRadius: radius,
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
