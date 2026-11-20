import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio_mobile_ui/common/tinta_dialog.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

Widget _app(AccentColor c, Widget dialog) =>
    ChangeNotifierProvider<SettingsProvider>.value(
      value: SettingsProvider.defaultSettings()
        ..update(accentColor: c, store: false),
      child: MaterialApp(home: Scaffold(body: dialog)),
    );

final _alert = TintaAlertDialog(
  icon: const Icon(Icons.watch_rounded),
  title: const Text('Cím'),
  content: const Text('Szöveg'),
  actions: [TextButton(onPressed: () {}, child: const Text('OK'))],
);

void main() {
  testWidgets('Üveg: the alert sits on glass, sized to its content',
      (tester) async {
    await tester.pumpWidget(_app(AccentColor.uveg, _alert));
    expect(find.byType(AdaptiveGlass), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    for (final t in ['Cím', 'Szöveg', 'OK']) {
      expect(find.text(t), findsOneWidget);
    }
    // not stretched over the whole screen
    final glass = tester.getSize(find.byType(AdaptiveGlass));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(glass.height, lessThan(screen.height / 2));
  });

  testWidgets('Kobalt: the plain AlertDialog, no glass', (tester) async {
    await tester.pumpWidget(_app(AccentColor.kobalt, _alert));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(AdaptiveGlass), findsNothing);
  });

  testWidgets('TintaDialog: glass only in Üveg', (tester) async {
    const d = TintaDialog(child: Text('Tartalom'));
    await tester.pumpWidget(_app(AccentColor.uveg, d));
    expect(find.byType(AdaptiveGlass), findsOneWidget);
    await tester.pumpWidget(_app(AccentColor.kobalt, d));
    expect(find.byType(AdaptiveGlass), findsNothing);
    expect(find.text('Tartalom'), findsOneWidget);
  });
}
