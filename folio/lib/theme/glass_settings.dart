import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// Tuned on a Redmi Note 12 Pro (Android 16, Vulkan) in the 2026-11-10 spike,
// see docs/superpowers/specs/2026-11-10-uveg-liquid-glass-design.md.

/// Bars and sheets: the iOS 27 material, frosted more so text behind the
/// glass isn't legible.
LiquidGlassSettings tintaBarSettings(bool dark) =>
    (dark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light)
        .copyWith(blur: 6);

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
