import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Üveg theme: the "wallpaper" behind the main pages. The theme background
/// with a few large, soft glows of the theme colours (which follow the
/// phone's wallpaper/system palette where available), so the glass navbar,
/// filters and sheets have colour to refract. Over a flat near-black
/// background glass reads as a grey pill (liquidglassdesign.com, 2026-11).
/// Painted BEHIND the content; plain gradients, no blur filter, never
/// animates, doesn't scroll.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, required this.background});

  /// The theme's normal page background (scaffoldBackgroundColor).
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final a = dark ? 0.30 : 0.22;

    Widget glow(Alignment center, double radius, Color c, double alpha) =>
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: radius,
              colors: [c.withValues(alpha: alpha), c.withValues(alpha: 0)],
            ),
          ),
          child: const SizedBox.expand(),
        );

    return IgnorePointer(
      child: RepaintBoundary(
        child: ColoredBox(
          color: background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              glow(const Alignment(-0.9, -0.9), 1.0, cs.secondary, a),
              glow(const Alignment(1.0, 0.1), 0.9, cs.tertiary, a * 0.8),
              glow(const Alignment(-0.6, 1.0), 1.0, cs.primary, a),
            ],
          ),
        ),
      ),
    );
  }
}

/// Üveg: the main pages run with a transparent scaffoldBackgroundColor so
/// [GlassBackdrop] shows. This hands down the real page colour for the few
/// places that still need it (frosted headers).
class GlassPageBackground extends InheritedWidget {
  const GlassPageBackground(
      {super.key, required this.color, required super.child});

  final Color color;

  static Color of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<GlassPageBackground>()
          ?.color ??
      Theme.of(context).scaffoldBackgroundColor;

  @override
  bool updateShouldNotify(GlassPageBackground old) => old.color != color;
}

/// Frosted fill for a pinned header in Üveg: content scrolling under it is
/// blurred into a colour wash instead of overlapping the header's text
/// (like the iOS navigation bar).
class GlassHeaderFill extends StatelessWidget {
  const GlassHeaderFill({super.key});

  @override
  Widget build(BuildContext context) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: ColoredBox(
            color: GlassPageBackground.of(context).withValues(alpha: 0.72),
            child: const SizedBox.expand(),
          ),
        ),
      );
}
