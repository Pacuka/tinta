import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_wear/widgets/day_switcher.dart';
import 'package:folio_wear/widgets/edge_fade.dart';
import 'package:folio_wear/widgets/page_title.dart';

void main() {
  test('middle of the screen stays full size', () {
    final e = edgeEffect(100.0, 200.0);
    expect(e.scale, 1.0);
    expect(e.opacity, 1.0);
    expect(edgeEffect(50.0, 200.0).scale, 1.0);
  });

  test('shrinks and fades towards both edges', () {
    final bottom = edgeEffect(200.0, 200.0);
    expect(bottom.scale, closeTo(0.75, 0.001));
    expect(bottom.opacity, closeTo(0.35, 0.001));
    expect(edgeEffect(0.0, 200.0).scale, closeTo(0.75, 0.001));
    final between = edgeEffect(175.0, 200.0);
    expect(between.scale, inExclusiveRange(0.75, 1.0));
  });

  test('never shrinks past the edge value off screen', () {
    expect(edgeEffect(500.0, 200.0).scale, closeTo(0.75, 0.001));
  });

  Future<void> pumpAt(WidgetTester tester, double top) async {
    tester.view.physicalSize = const Size(200, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [
        Positioned(
          top: top,
          left: 0,
          width: 100,
          height: 20,
          child: const EdgeFade(child: ColoredBox(color: Colors.red)),
        ),
      ]),
    ));
  }

  testWidgets('page titles fade with the list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PageTitle('Teendők')));
    expect(
        find.ancestor(of: find.text('Teendők'), matching: find.byType(EdgeFade)),
        findsOneWidget);
  });

  testWidgets('day switcher fades with the list', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DaySwitcher(nextLabel: 'Holnap', showNext: false, onChanged: (_) {}),
    ));
    expect(find.ancestor(of: find.text('Ma'), matching: find.byType(EdgeFade)),
        findsOneWidget);
  });

  testWidgets('item at the edge is painted through a transform',
      (tester) async {
    await pumpAt(tester, 170.0);
    expect(tester.layers.whereType<OpacityLayer>(), isNotEmpty);
  });

  testWidgets('item in the middle is painted untouched', (tester) async {
    await pumpAt(tester, 90.0);
    expect(tester.layers.whereType<OpacityLayer>(), isEmpty);
  });
}
