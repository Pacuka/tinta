import 'dart:math';
import 'package:flutter/material.dart';

/// Ring along the edge of the round screen, starting at 12 o'clock.
class ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  const ProgressRing({super.key, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _RingPainter(progress, color), size: Size.infinite);
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter(this.progress, this.color);

  static const _stroke = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - _stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
        rect.center, rect.width / 2, paint..color = const Color(0xFF1D2233));
    if (progress <= 0) return;
    canvas.drawArc(
        rect, -pi / 2, 2 * pi * progress, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
