import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/gradient_slider.dart';

/// Режим белого свечения: плавный переход тёплый ↔ холодный.
class WhiteTab extends StatelessWidget {
  const WhiteTab({
    super.key,
    required this.warm,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final int warm; // 0..100 (100 = максимально тёплый)
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientSlider(
          value: warm / 100.0,
          height: 48,
          gradient: const [Color(0xFFC9E2FF), Color(0xFFFFF5E8), Color(0xFFFFB46B)],
          onChanged: (t) => onChanged((t * 100).round()),
          onChangeEnd: (t) => onChangeEnd((t * 100).round()),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Холодный',
                style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text('Тёплый',
                style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
