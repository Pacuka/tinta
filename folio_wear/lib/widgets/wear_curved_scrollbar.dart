import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// HyperOS WearOS stílusú ívelt arc-scrollbar.
/// A képernyő jobb oldalán jelenik meg vékony ívként, a kör szélén.
/// Görgetéskor fade-in, majd 1.5s után automatikusan eltűnik.
class WearCurvedScrollbar extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const WearCurvedScrollbar({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<WearCurvedScrollbar> createState() => _WearCurvedScrollbarState();
}

class _WearCurvedScrollbarState extends State<WearCurvedScrollbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _hideTimer;

  double _fraction = 0.0;   // scrollFraction: 0.0 (teteje) → 1.0 (alja)
  double _thumbFrac = 1.0;  // thumb aránya az ívhez (viewport / teljes tartalom)
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    widget.controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    final pos = widget.controller.position;
    final max = pos.maxScrollExtent;
    setState(() {
      _hasContent = max > 0;
      _fraction = max > 0 ? (pos.pixels / max).clamp(0.0, 1.0) : 0.0;
      _thumbFrac = max > 0
          ? (pos.viewportDimension / (pos.viewportDimension + max))
              .clamp(0.10, 0.80)
          : 1.0;
    });
    if (_hasContent) {
      _fade.forward();
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) _fade.reverse();
      });
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _hideTimer?.cancel();
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Stack stays even without content: swapping it in during the first
    // swipe would rebuild the child and cancel that swipe.
    return Stack(
      children: [
        widget.child,
        if (_hasContent)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fade,
                child: CustomPaint(
                  painter: _HyperOSArcPainter(
                    fraction: _fraction,
                    thumbFrac: _thumbFrac,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HyperOSArcPainter extends CustomPainter {
  final double fraction;
  final double thumbFrac;

  // Ív a képernyő JOBB oldalán: 3 óra pozíciótól ±55° (összesen 110°)
  // HyperOS-ban szűkebb, de jól látható ív
  static const _startAngle = -pi * 55 / 180; // -55°
  static const _totalSweep = pi * 110 / 180;  // 110°

  const _HyperOSArcPainter({
    required this.fraction,
    required this.thumbFrac,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Kör középpontja és sugar — 5px befelé a szélektől
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.shortestSide / 2) - 5.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track — nagyon halvány fehér
    canvas.drawArc(
      rect, _startAngle, _totalSweep, false,
      Paint()
        ..color = const Color(0x16FFFFFF) // ~9% alpha
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Thumb — fehér, HyperOS stílus
    final thumbSweep = _totalSweep * thumbFrac;
    final thumbStart = _startAngle + fraction * (_totalSweep - thumbSweep);
    canvas.drawArc(
      rect, thumbStart, thumbSweep, false,
      Paint()
        ..color = const Color(0xCCFFFFFF) // ~80% white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HyperOSArcPainter old) =>
      old.fraction != fraction || old.thumbFrac != thumbFrac;
}
