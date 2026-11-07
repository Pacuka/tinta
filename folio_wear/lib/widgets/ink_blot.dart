import 'package:flutter/widgets.dart';

/// The blot from the Tinta logo, without the pen nib.
class InkBlot extends StatelessWidget {
  final double size;
  final Color color;
  const InkBlot({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _BlotPainter(color));
}

class _BlotPainter extends CustomPainter {
  final Color color;
  _BlotPainter(this.color);

  static const _viewBox = 108.0;

  static final _shape = Path()
    ..moveTo(55, 24)
    ..cubicTo(62, 24, 64, 32, 70, 31)
    ..cubicTo(76, 30, 82, 25, 85, 31)
    ..cubicTo(88, 37, 82, 41, 84, 46)
    ..cubicTo(86, 51, 94, 53, 91, 60)
    ..cubicTo(88, 67, 81, 63, 79, 69)
    ..cubicTo(77, 75, 81, 82, 73, 84)
    ..cubicTo(65, 86, 63, 78, 57, 80)
    ..cubicTo(51, 82, 48, 89, 42, 85)
    ..cubicTo(36, 81, 41, 75, 35, 72)
    ..cubicTo(29, 69, 22, 72, 22, 64)
    ..cubicTo(22, 56, 30, 57, 29, 50)
    ..cubicTo(28, 43, 20, 42, 25, 36)
    ..cubicTo(30, 30, 35, 37, 38, 31)
    ..cubicTo(40, 25, 43, 20, 47, 20)
    ..cubicTo(51, 20, 50, 24, 55, 24)
    ..close()
    ..addOval(Rect.fromCircle(center: const Offset(86, 82), radius: 5))
    ..addOval(Rect.fromCircle(center: const Offset(24, 32), radius: 3.5));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox);
    canvas.drawPath(_shape, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BlotPainter old) => old.color != color;
}
