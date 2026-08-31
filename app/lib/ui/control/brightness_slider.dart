import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/gradient_slider.dart';

/// Слайдер яркости: дорожка от тёмного к текущему цвету ленты.
class BrightnessSlider extends StatelessWidget {
  const BrightnessSlider({
    super.key,
    required this.value,
    required this.tint,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int value; // 0..100
  final Color tint;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.brightness_low_rounded,
            size: 20, color: AppColors.textFaint),
        const SizedBox(width: 12),
        Expanded(
          child: GradientSlider(
            value: value / 100.0,
            gradient: [
              const Color(0xFF0C0C12),
              Color.lerp(tint, Colors.white, 0.1) ?? tint,
            ],
            onChanged: (t) => onChanged((t * 100).round()),
            onChangeEnd: (t) => onChangeEnd((t * 100).round()),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 42,
          child: Text(
            '$value%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
