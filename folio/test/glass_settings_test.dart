import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/theme/glass_settings.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  test('bar glass is frosted more than the iOS 27 preset', () {
    expect(tintaBarSettings(true).blur, 6);
    expect(tintaBarSettings(false).blur, 6);
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
}
