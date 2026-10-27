import 'package:flutter/material.dart';

/// Üveg theme: three soft, static colour glows (blue, violet, teal) laid
/// over the app like ambient light, so the glass navbar and cards pick up a
/// faint tint. Each glow is a radial gradient fading to transparent, so no
/// blur filter has to run on every scroll frame. Never animates.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final k = dark ? 1.0 : 0.5;
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          // The blurred circles of the mockup reach about twice their size.
          Widget glow(Color color, double size, double cx, double cy,
              double alpha) {
            final r = size;
            return Positioned(
              left: cx - r,
              top: cy - r,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    color.withValues(alpha: alpha * k),
                    color.withValues(alpha: alpha * k * 0.45),
                    color.withValues(alpha: 0),
                  ], stops: const [0.0, 0.45, 1.0]),
                ),
                child: SizedBox(width: r * 2, height: r * 2),
              ),
            );
          }

          final s = w / 240;
          return Stack(clipBehavior: Clip.hardEdge, children: [
            glow(const Color(0xFF3B5BFF), 160 * s, -50 * s + 80 * s,
                -40 * s + 80 * s, 0.14),
            glow(const Color(0xFF8A3BFF), 130 * s, w * 0.6 + 65 * s,
                h * 0.4 + 65 * s, 0.10),
            glow(const Color(0xFF00B3A4), 120 * s, -30 * s + 60 * s,
                h * 0.75 + 60 * s, 0.09),
          ]);
        }),
      ),
    );
  }
}
