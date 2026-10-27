import 'package:flutter/material.dart';

/// A small line showing how the average moved over time (oldest left).
class AverageSparkline extends StatelessWidget {
  const AverageSparkline({super.key, required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 22,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(points, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.color);

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = points.reduce((a, b) => a < b ? a : b);
    var hi = points.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 0.01) {
      lo -= 0.5;
      hi += 0.5;
    }
    const pad = 2.0;
    final h = size.height - pad * 2;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = pad + h * (1 - (points[i] - lo) / (hi - lo));
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || old.points != points;
}
