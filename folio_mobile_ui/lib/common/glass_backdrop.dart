import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Üveg theme: three soft, static colour glows (blue, violet, teal) laid
/// over the app like ambient light, so the glass navbar and cards pick up a
/// faint tint. Painted once (RepaintBoundary) and never animates.
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
          Widget blob(Color color, double size, double left, double top,
                  double alpha) =>
              Positioned(
                left: left,
                top: top,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: alpha * k),
                  ),
                ),
              );
          return ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Stack(children: [
              blob(const Color(0xFF3B5BFF), 160 * w / 240, -50, -40, 0.14),
              blob(const Color(0xFF8A3BFF), 130 * w / 240, w * 0.6, h * 0.4,
                  0.10),
              blob(const Color(0xFF00B3A4), 120 * w / 240, -30, h * 0.75,
                  0.09),
            ]),
          );
        }),
      ),
    );
  }
}
