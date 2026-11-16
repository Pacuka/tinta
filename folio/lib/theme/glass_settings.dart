import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// Tuned on a Redmi Note 12 Pro (Android 16, Vulkan) in the 2026-11-10 spike,
// see docs/superpowers/specs/2026-11-10-uveg-liquid-glass-design.md.

/// Bars and sheets: the iOS 27 material, frosted more so text behind the
/// glass isn't legible.
LiquidGlassSettings tintaBarSettings(bool dark) =>
    (dark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light)
        .copyWith(blur: 6);

/// Sheets hold a lot of text, so on light glass the content behind must
/// stay a colour wash, never readable words (Redmi, "Több" sheet). Dark
/// keeps the bar material: the modal barrier already hides what's behind.
LiquidGlassSettings tintaSheetSettings(bool dark) => dark
    // Dark: the barrier already dims what's behind, so the sheet can be
    // much clearer than the bars and catch light on its rim like real glass
    // (blur 6 looked "túl matt", 2026-11-16).
    ? LiquidGlassSettings.ios27Dark
        .copyWith(blur: 2, frostOpacity: 0.7, lightIntensity: 0.6)
    : tintaBarSettings(false)
        .copyWith(blur: 20, glassColor: const Color(0xC8F8F8F8));

/// Opacity of content cards sitting on a glass sheet: low enough that the
/// glass shows, high enough that the text on them stays readable.
double tintaSheetCardAlpha(bool dark) => dark ? 0.55 : 0.6;

/// Opacity of the Üveg sheet panel. Without blur any see-through let the
/// text behind ghost through (0.86 and even 0.97 on the Redmi, 2026-11-16),
/// so the panel is solid, like an expanded iOS 26 sheet.
double tintaSheetPanelAlpha(bool dark) => 1.0;

/// The sliding lens of tab bars. 0 aberration counts as "unset" in the
/// package's indicator merge and brings back its 0.15 rainbow rim.
LiquidGlassSettings tintaIndicatorSettings() =>
    LiquidGlassSettings.ios27Indicator.copyWith(chromaticAberration: 0.001);

/// The selected tab at rest: a faint fill like on iOS, not a dark blob.
Color tintaIndicatorColor(bool dark) => dark
    ? Colors.white.withValues(alpha: 0.12)
    : Colors.black.withValues(alpha: 0.06);

/// Premium left a rainbow rim on the lens; standard renders it clean.
const GlassQuality tintaGlassQuality = GlassQuality.standard;

/// Selected tab/filter label. On light glass the wallpaper palette's
/// accent is too pale to read (Redmi, 2026-11-10), so it is darkened until
/// it reaches 4.5:1 against the surface; dark mode keeps the accent.
Color tintaSelectedColor(ColorScheme colorScheme, bool dark) {
  final accent = colorScheme.secondary;
  if (dark) return accent;
  final surface = colorScheme.surface.computeLuminance();
  var hsl = HSLColor.fromColor(accent);
  while (hsl.lightness > 0.05 &&
      (surface + 0.05) / (hsl.toColor().computeLuminance() + 0.05) < 4.5) {
    hsl = hsl.withLightness(hsl.lightness - 0.03);
  }
  return hsl.toColor();
}
