import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Индикатор уровня сигнала (RSSI) из четырёх столбиков.
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.rssi, this.size = 18});

  final int rssi;
  final double size;

  int get _level {
    if (rssi >= -60) return 4;
    if (rssi >= -72) return 3;
    if (rssi >= -84) return 2;
    if (rssi >= -95) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (i) {
          final active = i < level;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: size * 0.18,
            height: size * (0.35 + i * 0.22),
            decoration: BoxDecoration(
              color: active ? AppColors.success : AppColors.textFaint,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
