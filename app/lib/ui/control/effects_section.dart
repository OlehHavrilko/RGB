import 'package:flutter/material.dart';

import '../../protocol/effect_catalog.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/gradient_slider.dart';
import '../widgets/pressable.dart';

/// Сетка встроенных эффектов + слайдер скорости.
class EffectsSection extends StatelessWidget {
  const EffectsSection({
    super.key,
    required this.selectedId,
    required this.speed,
    required this.onSelect,
    required this.onSpeed,
    required this.onSpeedEnd,
  });

  final int? selectedId;
  final int speed; // 0..100
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onSpeed;
  final ValueChanged<int> onSpeedEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: kEffectCatalog.length,
          itemBuilder: (context, i) {
            final e = kEffectCatalog[i];
            final selected = e.id == selectedId;
            return Pressable(
              onTap: () => onSelect(e.id),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: Motion.fast,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      for (final c in e.previewColors) Color(c),
                      if (e.previewColors.length == 1) Color(e.previewColors.first),
                    ],
                  ),
                  border: Border.all(
                    color: selected ? Colors.white : AppColors.hairline,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Color(e.previewColors.first)
                                .withValues(alpha: 0.5),
                            blurRadius: 18,
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          e.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                    if (selected)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(Icons.check_circle,
                            color: Colors.white, size: 16),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.speed_rounded,
                size: 20, color: AppColors.textFaint),
            const SizedBox(width: 12),
            Expanded(
              child: GradientSlider(
                value: speed / 100.0,
                gradient: const [Color(0xFF14141C), AppColors.accent],
                onChanged: (t) => onSpeed((t * 100).round()),
                onChangeEnd: (t) => onSpeedEnd((t * 100).round()),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 42,
              child: Text(
                '$speed%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
