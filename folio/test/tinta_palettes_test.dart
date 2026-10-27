import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio/theme/colors/tinta_palettes.dart';

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('enum indexes of old values unchanged', () {
    expect(AccentColor.filc.index, 0);
    expect(AccentColor.adaptive.index, 11);
    expect(AccentColor.custom.index, 12);
    expect(AccentColor.kobalt.index, 13);
    expect(AccentColor.feketeSarga.index, 14);
    expect(AccentColor.petrol.index, 15);
  });

  test('kobalt light/dark values from spec', () {
    expect(tintaPalette(AccentColor.kobalt, Brightness.light)!.accent,
        const Color(0xFF2440C8));
    expect(tintaPalette(AccentColor.kobalt, Brightness.dark)!.accent,
        const Color(0xFF9DB0FF));
    expect(tintaPalette(AccentColor.kobalt, Brightness.light)!.background,
        const Color(0xFFF6F7F9));
    expect(tintaPalette(AccentColor.kobalt, Brightness.dark)!.background,
        const Color(0xFF101218));
  });

  test('petrol and fekete-sarga accents from spec', () {
    expect(tintaPalette(AccentColor.petrol, Brightness.light)!.accent,
        const Color(0xFF0F5C66));
    expect(tintaPalette(AccentColor.petrol, Brightness.dark)!.accent,
        const Color(0xFF5FC9D4));
    expect(tintaPalette(AccentColor.petrol, Brightness.light)!.examMark,
        const Color(0xFFE0A526));
    expect(tintaPalette(AccentColor.feketeSarga, Brightness.light)!.accent,
        const Color(0xFF121212));
    expect(tintaPalette(AccentColor.feketeSarga, Brightness.dark)!.accent,
        const Color(0xFFFFE14D));
  });

  test('uveg appended at the end with its palette', () {
    expect(AccentColor.uveg.index, 16);
    expect(tintaPalette(AccentColor.uveg, Brightness.dark)!.background,
        const Color(0xFF0D0F15));
    expect(tintaPalette(AccentColor.uveg, Brightness.light)!.background,
        const Color(0xFFEEF1F8));
  });

  test('non-tinta accents return null', () {
    expect(tintaPalette(AccentColor.adaptive, Brightness.light), isNull);
    expect(tintaPalette(AccentColor.filc, Brightness.dark), isNull);
  });

  test('accent vs background contrast >= 3 for all tinta themes', () {
    for (final c in [
      AccentColor.kobalt,
      AccentColor.feketeSarga,
      AccentColor.petrol,
      AccentColor.uveg
    ]) {
      for (final b in Brightness.values) {
        final p = tintaPalette(c, b)!;
        expect(contrastRatio(p.accent, p.background),
            greaterThanOrEqualTo(3.0),
            reason: '$c $b');
        expect(contrastRatio(p.onAccent, p.accent), greaterThanOrEqualTo(4.5),
            reason: 'onAccent $c $b');
      }
    }
  });
}
