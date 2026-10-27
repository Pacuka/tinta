import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:folio/helpers/motion_once.dart';

/// How the ink line appears: [pen] draws it with a small nib, [drop] lets a
/// drop fall and spread into the line, [blot] soaks in from blurry to sharp,
/// [still] is just there.
enum InkStyle { pen, drop, blot, still }

/// Tinta's page signature: an ink line under the header. Each page can use
/// its own [style]; with a [motionKey] it animates only once per app launch.
/// Respects the system "remove animations" setting.
class InkStroke extends StatefulWidget {
  const InkStroke(
      {super.key, this.padding, this.style = InkStyle.pen, this.motionKey});

  final EdgeInsetsGeometry? padding;
  final InkStyle style;
  final String? motionKey;

  @override
  State<InkStroke> createState() => _InkStrokeState();
}

class _InkStrokeState extends State<InkStroke>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(
        milliseconds: switch (widget.style) {
      InkStyle.pen => 1350,
      InkStyle.drop => 1050,
      InkStyle.blot => 800,
      InkStyle.still => 1,
    }),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed) {
      final skip = widget.style == InkStyle.still ||
          MediaQuery.of(context).disableAnimations ||
          (widget.motionKey != null &&
              !MotionOnce.shouldPlay(widget.motionKey!));
      if (skip) {
        _c.value = 1.0;
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: widget.padding ??
          const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 10.0),
      child: SizedBox(
        height: 26.0,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            switch (widget.style) {
              case InkStyle.drop:
                return CustomPaint(
                    painter: _DropPainter(t: t, color: color));
              case InkStyle.blot:
                final v = Curves.easeOut.transform(t);
                final line =
                    CustomPaint(painter: _InkPainter(t: 1, color: color));
                return Opacity(
                  opacity: v,
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.diagonal3Values(0.6 + 0.4 * v, 1, 1),
                    child: v >= 1
                        ? line
                        : ImageFiltered(
                            imageFilter: ImageFilter.blur(
                                sigmaX: 6 * (1 - v), sigmaY: 6 * (1 - v)),
                            child: line),
                  ),
                );
              case InkStyle.pen:
              case InkStyle.still:
                return CustomPaint(painter: _InkPainter(t: t, color: color));
            }
          },
        ),
      ),
    );
  }
}

/// A drop falls onto the line's start, then spreads into the line and the
/// end dot.
class _DropPainter extends CustomPainter {
  _DropPainter({required this.t, required this.color});

  final double t;
  final Color color;

  double _seg(double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    const y = _InkPainter._y;
    final endX = size.width * _InkPainter._lineEnd;
    final fall = Curves.easeIn.transform(_seg(0.0, 0.43));
    if (t < 0.43) {
      canvas.drawCircle(
          Offset(4, -4 + (y + 4) * fall), 3.6, Paint()..color = color);
      return;
    }
    final spread = const Cubic(.2, .8, .2, 1).transform(_seg(0.43, 1.0));
    final x = 8 + (endX - 8) * spread;
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 2.5, x, y + 2.5, const Radius.circular(2.5)),
      Paint()
        ..shader = LinearGradient(colors: [
          color,
          color,
          color.withValues(alpha: 0.35),
        ], stops: const [0, 0.75, 1])
            .createShader(Rect.fromLTRB(0, 0, endX, size.height)),
    );
    final dab = Curves.easeOutBack.transform(_seg(0.85, 1.0));
    if (dab > 0) {
      canvas.drawCircle(Offset(endX + 4, y), 3.6 * dab, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_DropPainter old) => old.t != t || old.color != color;
}

class _InkPainter extends CustomPainter {
  _InkPainter({required this.t, required this.color});

  final double t;
  final Color color;

  static const _lineEnd = 0.58; // fraction of the width
  static const _y = 22.0; // baseline of the line inside the box

  double _seg(double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeInOutCubic;
    final endX = size.width * _lineEnd;

    // Line: drawn between 11% and 63% of the timeline.
    final draw = ease.transform(_seg(0.11, 0.63));
    final x = endX * draw;
    if (x > 0) {
      final rect = RRect.fromLTRBR(
          0, _y - 2.5, x, _y + 2.5, const Radius.circular(2.5));
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(colors: [
            color,
            color,
            color.withValues(alpha: 0.35),
          ], stops: const [0, 0.75, 1])
              .createShader(Rect.fromLTRB(0, 0, endX, size.height)),
      );
    }

    // Dot: dabbed when the pen presses down (70%).
    final dab = Curves.easeOutBack.transform(_seg(0.66, 0.76));
    if (dab > 0) {
      canvas.drawCircle(
          Offset(endX + 4, _y), 3.6 * dab, Paint()..color = color);
    }

    // Pen: follows the line tip, presses, then lifts up-right and fades.
    double px = x, py = _y, opacity, angle = 0;
    final appear = _seg(0.0, 0.11);
    final press = _seg(0.63, 0.70);
    final release = _seg(0.70, 0.78);
    final lift = Curves.easeIn.transform(_seg(0.78, 1.0));
    opacity = appear * (1 - lift);
    if (t >= 0.63) {
      px = endX + 4;
      py = _y + 3 * (press - release);
      angle = -0.1 * (press - release);
    }
    px += 26 * lift;
    py -= 26 * lift;
    angle += 0.2 * lift;
    if (opacity <= 0) return;

    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(angle);
    _drawNib(canvas, color.withValues(alpha: opacity));
    canvas.restore();
  }

  // A small fountain-pen nib whose tip sits at (0,0), pointing down-left.
  void _drawNib(Canvas canvas, Color c) {
    canvas.saveLayer(const Rect.fromLTRB(-20, -20, 20, 20), Paint());
    canvas.rotate(0.7); // tip toward the line, body up-right
    canvas.translate(-6, -15);
    final body = Path()
      ..moveTo(6, 15)
      ..lineTo(1.6, 7)
      ..quadraticBezierTo(1.2, 6.2, 1.8, 5.2)
      ..lineTo(4.4, 1.6)
      ..lineTo(7.6, 1.6)
      ..lineTo(10.2, 5.2)
      ..quadraticBezierTo(10.8, 6.2, 10.4, 7)
      ..close();
    canvas.drawPath(body, Paint()..color = c);
    canvas.drawRRect(
        RRect.fromLTRBR(4.0, -1.2, 8.0, 1.8, const Radius.circular(0.8)),
        Paint()..color = c);
    final cut = Paint()
      ..color = const Color(0xFF000000)
      ..blendMode = BlendMode.dstOut;
    canvas.drawCircle(const Offset(6, 7.4), 1.2, cut);
    canvas.drawLine(const Offset(6, 8.4), const Offset(6, 14),
        cut..strokeWidth = 0.9);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InkPainter old) => old.t != t || old.color != color;
}
