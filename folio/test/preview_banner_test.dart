import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/release.dart';
import 'package:folio_mobile_ui/common/widgets/update/preview_banner.dart';

void main() {
  testWidgets('pre-release banner is small and warns', (tester) async {
    final release = Release.fromJson(
        {"tag_name": "v1.4.0", "prerelease": true, "assets": []});
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PreviewBanner(release, onTap: () {}))));
    expect(find.text("Előzetes, nem tesztelt verzió: v1.4.0"), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(PreviewBanner)).height, lessThan(80));
  });

  test('dialog warning text', () {
    expect(previewWarning,
        "Ezt a verziót még nem próbálták ki éles iskolai fiókkal, lehetnek benne hibák. Csak akkor telepítsd, ha szívesen segítesz tesztelni!");
  });
}
