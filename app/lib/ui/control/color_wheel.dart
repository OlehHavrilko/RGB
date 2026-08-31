import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Круглый HSV-селектор: угол — оттенок, радиус — насыщенность.
/// Яркость задаётся отдельным слайдером, поэтому value здесь всегда 1.
class ColorWheel extends StatefulWidget {
  const ColorWheel({
    super.key,
    required this.color,
    required this.onChanged,
    this.onChangeEnd,
    this.size = 260,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final ValueChanged<Color>? onChangeEnd;
  final double size;

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  late HSVColor _hsv;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(ColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.color != oldWidget.color) {
      _hsv = HSVColor.fromColor(widget.color);
    }
  }

  void _handle(Offset local, {required bool end}) {
    final r = widget.size / 2;
    final center = Offset(r, r);
    final v = local - center;
    final dist = v.distance;
    final sat = (dist / r).clamp(0.0, 1.0);
    var hue = (math.atan2(v.dy, v.dx) * 180 / math.pi) % 360;
    if (hue < 0) hue += 360;

    final next = HSVColor.fromAHSV(1, hue, sat, 1);
    if ((next.hue - _hsv.hue).abs() > 2 ||
        (next.saturation - _hsv.saturation).abs() > 0.03) {
      HapticFeedback.selectionClick();
    }
    setState(() => _hsv = next);
    final color = next.toColor();
    widget.onChanged(color);
    if (end) widget.onChangeEnd?.call(color);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.size / 2;
    final thumbAngle = _hsv.hue * math.pi / 180;
    final thumbRadius = _hsv.saturation * r;
    final thumbPos = Offset(
      r + thumbRadius * math.cos(thumbAngle),
      r + thumbRadius * math.sin(thumbAngle),
    );

    return GestureDetector(
      onPanStart: (d) {
        _dragging = true;
        _handle(d.localPosition, end: false);
      },
      onPanUpdate: (d) => _handle(d.localPosition, end: false),
      onPanEnd: (_) {
        _dragging = false;
        widget.onChangeEnd?.call(_hsv.toColor());
      },
      onTapUp: (d) => _handle(d.localPosition, end: true),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _hsv.toColor().withValues(alpha: 0.45),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CustomPaint(painter: _WheelPainter()),
            ),
            AnimatedPositioned(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              left: thumbPos.dx - 15,
              top: thumbPos.dy - 15,
              child: AnimatedScale(
                scale: _dragging ? 1.2 : 1,
                duration: const Duration(milliseconds: 140),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hsv.toColor(),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
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
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final huePaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, huePaint);

    final satPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, Colors.white.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, satPaint);

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.hairline,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
