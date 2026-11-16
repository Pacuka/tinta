import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression (2026-11-16): flutter_linkify's SelectableLinkify forwards a
/// null contextMenuBuilder to SelectableText, which hides the Copy menu, so
/// homework/message text could be selected but not copied. Every use must
/// pass its own builder.
void main() {
  test('every SelectableLinkify passes a contextMenuBuilder', () {
    final roots = [Directory('../folio_mobile_ui/lib'), Directory('lib')];
    final missing = <String>[];
    for (final root in roots) {
      for (final f in root.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final src = f.readAsStringSync();
        var i = src.indexOf('SelectableLinkify(');
        while (i != -1) {
          // the call's own arguments come right after; 600 chars covers them
          final window = src.substring(i, (i + 600).clamp(0, src.length));
          if (!window.contains('contextMenuBuilder:')) missing.add(f.path);
          i = src.indexOf('SelectableLinkify(', i + 1);
        }
      }
    }
    expect(missing, isEmpty);
  });
}
