import 'package:flutter/material.dart';

import '../../state/led_state.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/pressable.dart';

/// Переключатель активного режима: Цвет / Белый / Эффекты.
class ModeSwitcher extends StatelessWidget {
  const ModeSwitcher({super.key, required this.mode, required this.onChanged});

  final LedMode mode;
  final ValueChanged<LedMode> onChanged;

  static const _items = [
    (LedMode.color, 'Цвет', Icons.palette_outlined),
    (LedMode.white, 'Белый', Icons.wb_sunny_outlined),
    (LedMode.effect, 'Эффекты', Icons.auto_awesome_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segW = constraints.maxWidth / _items.length;
        final index = _items.indexWhere((e) => e.$1 == mode);
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.base,
                curve: Motion.emphasizedCurve,
                left: segW * index + 4,
                top: 4,
                bottom: 4,
                width: segW - 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.scanPulse),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final item in _items)
                    Expanded(
                      child: Pressable(
                        haptic: true,
                        onTap: () => onChanged(item.$1),
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.$3,
                                  size: 16,
                                  color: item.$1 == mode
                                      ? Colors.white
                                      : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                item.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: item.$1 == mode
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
