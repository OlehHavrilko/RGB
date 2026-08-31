import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Горизонтальный слайдер с произвольным градиентом дорожки и крупным
/// перетаскиваемым бегунком. Значение нормировано в диапазоне [0, 1].
class GradientSlider extends StatefulWidget {
  const GradientSlider({
    super.key,
    required this.value,
    required this.gradient,
    required this.onChanged,
    this.onChangeEnd,
    this.height = 44,
    this.thumbColor,
  });

  final double value;
  final List<Color> gradient;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double height;
  final Color? thumbColor;

  @override
  State<GradientSlider> createState() => _GradientSliderState();
}

class _GradientSliderState extends State<GradientSlider> {
  double _localValue = 0;
  bool _dragging = false;

  double get _value => _dragging ? _localValue : widget.value;

  void _update(double dx, double width) {
    final v = (dx / width).clamp(0.0, 1.0);
    if ((v - _localValue).abs() > 0.001) HapticFeedback.selectionClick();
    setState(() => _localValue = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            _dragging = true;
            _localValue = widget.value;
            _update(d.localPosition.dx, width);
          },
          onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, width),
          onHorizontalDragEnd: (_) {
            _dragging = false;
            widget.onChangeEnd?.call(_localValue);
          },
          onTapDown: (d) {
            _dragging = true;
            _localValue = widget.value;
            _update(d.localPosition.dx, width);
          },
          onTapUp: (_) {
            _dragging = false;
            widget.onChangeEnd?.call(_localValue);
          },
          child: SizedBox(
            height: widget.height,
            width: width,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    gradient: LinearGradient(colors: widget.gradient),
                    border: Border.all(color: AppColors.hairline),
                  ),
                ),
                Positioned(
                  left: (_value * (width - widget.height))
                      .clamp(0.0, width - widget.height),
                  child: AnimatedScale(
                    scale: _dragging ? 1.12 : 1,
                    duration: const Duration(milliseconds: 140),
                    child: Container(
                      width: widget.height,
                      height: widget.height,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.thumbColor ?? Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
