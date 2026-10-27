import 'package:flutter_test/flutter_test.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio/theme/glass.dart';

void main() {
  test('Üveg follows the phone colours when the system offers them', () {
    expect(followsSystemColors(AccentColor.uveg, hasSystemPalette: true), isTrue);
    expect(followsSystemColors(AccentColor.adaptive, hasSystemPalette: true), isTrue);
  });

  test('Üveg falls back to its own blue without system colours (iPhone)', () {
    expect(followsSystemColors(AccentColor.uveg, hasSystemPalette: false), isFalse);
  });

  test('fixed Tinta themes never follow the phone', () {
    expect(followsSystemColors(AccentColor.kobalt, hasSystemPalette: true), isFalse);
    expect(followsSystemColors(AccentColor.petrol, hasSystemPalette: true), isFalse);
  });
}
