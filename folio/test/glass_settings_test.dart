import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/theme/glass_settings.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  test('bar glass is frosted more than the iOS 27 preset', () {
    expect(tintaBarSettings(true).blur, 6);
    expect(tintaBarSettings(false).blur, 6);
  });

  test('light sheets are frosted harder than bars, dark ones are not', () {
    expect(tintaSheetSettings(false).blur,
        greaterThan(tintaBarSettings(false).blur));
    expect(tintaSheetSettings(false).glassColor.a,
        greaterThan(tintaBarSettings(false).glassColor.a));
    expect(tintaSheetSettings(true), tintaBarSettings(true));
  });

  test('indicator lens has no rainbow rim (0 would mean "unset")', () {
    expect(tintaIndicatorSettings().chromaticAberration, 0.001);
  });

  test('resting indicator is a faint fill, not a dark blob', () {
    expect(tintaIndicatorColor(true), Colors.white.withValues(alpha: 0.12));
    expect(tintaIndicatorColor(false), Colors.black.withValues(alpha: 0.06));
  });

  test('glass widgets use the standard shader', () {
    expect(tintaGlassQuality, GlassQuality.standard);
  });

  test('selected label is dark enough on light glass', () {
    // A wallpaper palette like the one on the Redmi: pale secondary.
    const pale = Color(0xFF8DB4E2);
    const light = ColorScheme.light(
        primary: pale, secondary: pale, surface: Color(0xFFEDEFF3));
    final dark = ColorScheme.fromSeed(
        seedColor: const Color(0xFF7FA6D9), brightness: Brightness.dark);
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
    }

    final picked = tintaSelectedColor(light, false);
    expect(contrast(picked, light.surface), greaterThanOrEqualTo(4.5));
    // Still the same blue, only darker.
    expect(
        (HSLColor.fromColor(picked).hue - HSLColor.fromColor(pale).hue).abs(),
        lessThan(1.0));
    expect(tintaSelectedColor(dark, true), dark.secondary);
  });
}
