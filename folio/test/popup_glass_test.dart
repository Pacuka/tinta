import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio/theme/glass.dart';
import 'package:provider/provider.dart';

Widget _app(AccentColor c, Widget Function(BuildContext) build) =>
    ChangeNotifierProvider<SettingsProvider>.value(
      value: SettingsProvider.defaultSettings()
        ..update(accentColor: c, store: false),
      child: MaterialApp(home: Scaffold(body: Builder(builder: build))),
    );

const _art = SizedBox(width: 100, height: 200, key: Key('art'));
const _stops = [0.0, 0.3, 0.6, 0.95];

void main() {
  testWidgets('Üveg: popup background is transparent, art is masked',
      (tester) async {
    late Color bg;
    await tester.pumpWidget(_app(AccentColor.uveg, (context) {
      bg = popupBackground(context);
      return popupArtFade(context, stops: _stops, child: _art);
    }));
    expect(bg.a, 0); // see-through …
    expect(bg.r, isNot(0)); // … but page-coloured, not black (grey band)
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.byKey(const Key('art')), findsOneWidget);
  });

  testWidgets('Kobalt: scaffold colour and untouched art', (tester) async {
    late Color bg;
    late Color scaffold;
    await tester.pumpWidget(_app(AccentColor.kobalt, (context) {
      bg = popupBackground(context);
      scaffold = Theme.of(context).scaffoldBackgroundColor;
      return popupArtFade(context, stops: _stops, child: _art);
    }));
    expect(bg, scaffold);
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byKey(const Key('art')), findsOneWidget);
  });
}
