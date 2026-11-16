import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_mobile_ui/common/glass_backdrop.dart';

void main() {
  testWidgets('backdrop paints a wash without any full-screen blur filter',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: GlassBackdrop(background: Color(0xFF101218))));
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
        find.descendant(
            of: find.byType(GlassBackdrop),
            matching: find.byType(CustomPaint)),
        findsWidgets);
  });
}
