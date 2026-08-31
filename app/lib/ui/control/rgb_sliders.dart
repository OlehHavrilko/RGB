import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/gradient_slider.dart';

/// Три слайдера каналов R/G/B, синхронизированные с цветовым кругом.
class RgbSliders extends StatelessWidget {
  const RgbSliders({
    super.key,
    required this.color,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final ValueChanged<Color> onChangeEnd;

  int get _r => (color.r * 255).round();
  int get _g => (color.g * 255).round();
  int get _b => (color.b * 255).round();

  Color _withR(int v) => Color.fromARGB(255, v, _g, _b);
  Color _withG(int v) => Color.fromARGB(255, _r, v, _b);
  Color _withB(int v) => Color.fromARGB(255, _r, _g, v);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('R', _r, const [Color(0xFF1A0000), Color(0xFFFF3B3B)],
            (v) => _withR(v)),
        const SizedBox(height: 12),
        _row('G', _g, const [Color(0xFF001A08), Color(0xFF35E06B)],
            (v) => _withG(v)),
        const SizedBox(height: 12),
        _row('B', _b, const [Color(0xFF00081A), Color(0xFF3B7BFF)],
            (v) => _withB(v)),
      ],
    );
  }

  Widget _row(String label, int value, List<Color> gradient,
      Color Function(int) build) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GradientSlider(
            value: value / 255.0,
            gradient: gradient,
            height: 34,
            onChanged: (t) => onChanged(build((t * 255).round())),
            onChangeEnd: (t) => onChangeEnd(build((t * 255).round())),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textFaint,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
