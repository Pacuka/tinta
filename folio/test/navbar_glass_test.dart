import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio_mobile_ui/screens/navigation/nabar.dart';
import 'package:folio_mobile_ui/screens/navigation/navbar_item.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

// Runs on the test host (not iOS), so Navbar takes the Android path.
Widget _app(SettingsProvider settings, void Function(int) onSelected) =>
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: MaterialApp(
        home: Scaffold(
          bottomNavigationBar: Navbar(
            selectedIndex: 0,
            onSelected: onSelected,
            items: [
              for (final t in ['Kezdőlap', 'Jegyek', 'Órarend', 'Több'])
                NavItem(
                    title: t,
                    icon: const Icon(Icons.circle_outlined),
                    activeIcon: const Icon(Icons.circle)),
            ],
          ),
        ),
      ),
    );

SettingsProvider _settings(AccentColor c) =>
    SettingsProvider.defaultSettings()..update(accentColor: c, store: false);

void main() {
  testWidgets('Üveg on Android: Liquid Glass tab bar, no old blur capsule',
      (tester) async {
    await tester.pumpWidget(_app(_settings(AccentColor.uveg), (_) {}));
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(Navbar), matching: find.byType(BackdropFilter)),
        findsNothing);
  });

  testWidgets('Kobalt keeps the classic bar', (tester) async {
    await tester.pumpWidget(_app(_settings(AccentColor.kobalt), (_) {}));
    expect(find.byType(GlassTabBar), findsNothing);
  });

  testWidgets('switching Üveg → Kobalt drops the glass bar without restart',
      (tester) async {
    final settings = _settings(AccentColor.uveg);
    await tester.pumpWidget(_app(settings, (_) {}));
    expect(find.byType(GlassTabBar), findsOneWidget);
    await settings.update(accentColor: AccentColor.kobalt, store: false);
    await tester.pump();
    expect(find.byType(GlassTabBar), findsNothing);
  });

  testWidgets('tapping the third tab selects index 2', (tester) async {
    int? picked;
    await tester.pumpWidget(_app(_settings(AccentColor.uveg), (i) => picked = i));
    await tester.tap(find.text('Órarend'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(picked, 2);
  });
}
