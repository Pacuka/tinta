import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/ui/flutter_colorpicker/utils.dart';

void main() {
  test('0-255 channels match the old Color.red/green/blue/alpha', () {
    for (final v in [
      0x00000000,
      0xFFFFFFFF,
      0x80123456,
      0xFF12AB34,
      0x01FE7F80
    ]) {
      final c = Color(v);
      expect(c.alpha8, (v >> 24) & 0xff);
      expect(c.red8, (v >> 16) & 0xff);
      expect(c.green8, (v >> 8) & 0xff);
      expect(c.blue8, v & 0xff);
      // Stored themes/settings use this int: it must not change.
      expect(c.toARGB32(), v);
    }
  });

  test('hex text is unchanged', () {
    expect(colorToHex(const Color(0x80123456)), '80123456');
    expect(colorToHex(const Color(0xFF12AB34), enableAlpha: false), '12AB34');
  });
}
