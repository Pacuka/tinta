import 'package:flutter/material.dart';

/// Üveg theme: one soft glow of the theme colour (which follows the phone's
/// wallpaper/system theme where available) fading down from the top, so the
/// glass navbar and chips have something to catch. A plain gradient, no blur
/// filter, never animates.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final c = theme.colorScheme.secondary;
    return IgnorePointer(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.6, -1.1),
              radius: 1.3,
              colors: [
                c.withValues(alpha: dark ? 0.12 : 0.08),
                c.withValues(alpha: 0),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
