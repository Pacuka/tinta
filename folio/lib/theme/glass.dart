import 'package:flutter/material.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:provider/provider.dart';

/// True while the "Üveg" (Liquid Glass-like) theme is selected. Everything
/// glassy is gated by this, so other themes stay untouched.
bool isGlassTheme(BuildContext context) =>
    Provider.of<SettingsProvider>(context).accentColor == AccentColor.uveg;

/// [isGlassTheme] for callbacks (no listening). A tree without settings
/// (some widget tests) counts as "not glass".
bool isGlassThemeNow(BuildContext context) {
  try {
    return Provider.of<SettingsProvider>(context, listen: false).accentColor ==
        AccentColor.uveg;
  } on ProviderNotFoundException {
    return false;
  }
}

/// Üveg theme: the hairline of light around cards; [BorderSide.none] for
/// every other theme.
BorderSide glassHairline(BuildContext context) => isGlassTheme(context)
    ? BorderSide(
        width: 0.8,
        color: Colors.white.withValues(
            alpha:
                Theme.of(context).brightness == Brightness.dark ? 0.07 : 0.8))
    : BorderSide.none;

/// Card corner radius: a little rounder in the Üveg theme.
double glassRadius(BuildContext context, double normal) =>
    isGlassTheme(context) ? 18.0 : normal;

/// Whether the theme takes its colours from the phone (wallpaper / system
/// theme, e.g. HyperOS or Material You). Üveg does when the phone offers
/// them; otherwise (iPhone, older Android) it keeps its own blue palette.
bool followsSystemColors(AccentColor c, {required bool hasSystemPalette}) =>
    c == AccentColor.adaptive || (c == AccentColor.uveg && hasSystemPalette);

/// Detail popups (grade, homework, lesson…) paint their own sheet colour.
/// In Üveg it is transparent so the glass sheet beneath shows through.
///
/// The page colour at 0 alpha, NOT [Colors.transparent]: the popups fade
/// with `.withValues(alpha: 0.1)`, and transparent *black* at 10% laid a
/// grey band over light-mode sheets (2026-11-16).
Color popupBackground(BuildContext context) => isGlassTheme(context)
    ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0)
    : Theme.of(context).scaffoldBackgroundColor;

/// The cover art on detail popups fades out under an overlay of the sheet
/// colour. With a transparent sheet (Üveg) that overlay does nothing, so the
/// art is masked with the same profile instead: hidden → 90% → 90% → hidden,
/// measured on the art itself so it always fades out before its own bottom
/// edge (the art is often shorter than the overlay). Other themes get [child]
/// unchanged.
Widget popupArtFade(
  BuildContext context, {
  required List<double> stops,
  required Widget child,
}) {
  if (!isGlassTheme(context)) return child;
  return ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.9),
        Colors.black.withValues(alpha: 0.9),
        Colors.black.withValues(alpha: 0.0),
      ],
      stops: stops,
    ).createShader(bounds),
    child: child,
  );
}
