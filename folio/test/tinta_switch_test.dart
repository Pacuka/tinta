import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio_mobile_ui/common/tinta_switch.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

Widget _app(SettingsProvider s, Widget child) =>
    ChangeNotifierProvider<SettingsProvider>.value(
      value: s,
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

SettingsProvider _s(AccentColor c) =>
    SettingsProvider.defaultSettings()..update(accentColor: c, store: false);

void main() {
  testWidgets('Kobalt: Material Switch, tap toggles', (tester) async {
    bool? got;
    await tester.pumpWidget(_app(_s(AccentColor.kobalt),
        TintaSwitch(value: false, onChanged: (v) => got = v)));
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(GlassSwitch), findsNothing);
    await tester.tap(find.byType(Switch));
    expect(got, true);
  });

  testWidgets('Üveg: glass switch, tap toggles', (tester) async {
    bool? got;
    await tester.pumpWidget(_app(_s(AccentColor.uveg),
        TintaSwitch(value: false, onChanged: (v) => got = v)));
    expect(find.byType(GlassSwitch), findsOneWidget);
    await tester.tap(find.byType(GlassSwitch));
    await tester.pumpAndSettle();
    expect(got, true);
  });

  testWidgets('Üveg: onChanged null = disabled, tap does nothing',
      (tester) async {
    await tester.pumpWidget(_app(_s(AccentColor.uveg),
        const TintaSwitch(value: false, onChanged: null)));
    await tester.tap(find.byType(GlassSwitch), warnIfMissed: false);
    await tester.pumpAndSettle();
    final ignore = tester.widget<IgnorePointer>(find
        .ancestor(
            of: find.byType(GlassSwitch), matching: find.byType(IgnorePointer))
        .first);
    expect(ignore.ignoring, true);
  });

  testWidgets('switching theme Üveg → Kobalt brings back Material Switch',
      (tester) async {
    final s = _s(AccentColor.uveg);
    await tester.pumpWidget(
        _app(s, TintaSwitch(value: true, onChanged: (_) {})));
    expect(find.byType(GlassSwitch), findsOneWidget);
    s.update(accentColor: AccentColor.kobalt, store: false);
    await tester.pumpAndSettle();
    expect(find.byType(GlassSwitch), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('no SettingsProvider: plain Switch, no crash', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TintaSwitch(value: true, onChanged: (_) {}))));
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('Kobalt: Material Slider keeps its parameters', (tester) async {
    await tester.pumpWidget(_app(
        _s(AccentColor.kobalt),
        TintaSlider(
            value: 0.5, divisions: 4, label: 'x', onChanged: (_) {})));
    final s = tester.widget<Slider>(find.byType(Slider));
    expect(s.divisions, 4);
    expect(s.label, 'x');
  });

  testWidgets('Üveg: glass slider keeps divisions', (tester) async {
    await tester.pumpWidget(_app(
        _s(AccentColor.uveg),
        SizedBox(
            width: 300,
            child: TintaSlider(value: 0.5, divisions: 4, onChanged: (_) {}))));
    final g = tester.widget<GlassSlider>(find.byType(GlassSlider));
    expect(g.divisions, 4);
    expect(g.value, 0.5);
  });
}
