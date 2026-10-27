import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_mobile_ui/common/glass_backdrop.dart';

void main() {
  testWidgets('backdrop glows without a full-screen blur filter',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GlassBackdrop()));
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(DecoratedBox).evaluate().isNotEmpty ||
        find.byType(Container).evaluate().isNotEmpty, isTrue);
  });
}
