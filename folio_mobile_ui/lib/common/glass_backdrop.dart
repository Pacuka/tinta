import 'package:flutter/material.dart';

/// Üveg theme: the "wallpaper" behind the main pages. The page colour with
/// one quiet wash of the theme colour (which follows the phone's wallpaper
/// palette where available) fading out from the top, like iOS Weather or
/// Music. Gives the glass bars something to refract; over a flat near-black
/// page glass reads as a grey pill (liquidglassdesign.com). No blobs: the
/// three-glow "aurora" looked like generic AI art (user, 2026-11-16).
/// Painted BEHIND the content, in screen coordinates, so a header can paint
/// the exact same pixels ([GlassHeaderFill]). Never animates or scrolls.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, required this.background});

  /// The theme's normal page background (scaffoldBackgroundColor).
  final Color background;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _WashPainter(
              background: background,
              wash: _washColor(context),
              screenHeight: MediaQuery.sizeOf(context).height,
              top: 0,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}

Color _washColor(BuildContext context) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  return theme.colorScheme.secondary.withValues(alpha: dark ? 0.20 : 0.14);
}

/// Page colour + the top wash, laid out against the whole screen. [top] is
/// where this box starts on screen, so a header paints the same pixels as
/// the backdrop behind it.
class _WashPainter extends CustomPainter {
  _WashPainter({
    required this.background,
    required this.wash,
    required this.screenHeight,
    required this.top,
  });

  final Color background;
  final Color wash;
  final double screenHeight;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = background);
    final screen = Rect.fromLTWH(0, -top, size.width, screenHeight);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [wash, wash.withValues(alpha: 0)],
          stops: const [0.0, 0.55],
        ).createShader(screen),
    );
  }

  @override
  bool shouldRepaint(_WashPainter old) =>
      old.background != background ||
      old.wash != wash ||
      old.screenHeight != screenHeight ||
      old.top != top;
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

/// Fill for a pinned header in Üveg: paints exactly the backdrop behind it,
/// so the header is invisible at rest, and fades out over its last
/// [fade] px. Keep it short: the filter bar sits at the bottom of the
/// header, and an 18 px fade let a scrolled date show through the glass
/// filters (2026-11-16). [screenTop] = where the header
/// starts on screen.
class GlassHeaderFill extends StatelessWidget {
  const GlassHeaderFill({super.key, this.screenTop = 0, this.fade = 4});

  final double screenTop;
  final double fade;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: LayoutBuilder(builder: (context, c) {
          final h = c.maxHeight;
          final solid = h <= fade ? 0.0 : (h - fade) / h;
          return ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Colors.black, Colors.black, Colors.transparent],
              stops: [0.0, solid, 1.0],
            ).createShader(r),
            child: CustomPaint(
              painter: _WashPainter(
                background: GlassPageBackground.of(context),
                wash: _washColor(context),
                screenHeight: MediaQuery.sizeOf(context).height,
                top: screenTop,
              ),
              child: const SizedBox.expand(),
            ),
          );
        }),
      );
}
