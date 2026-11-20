import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/tinta_dropdown.dart';
import 'package:provider/provider.dart';

Widget _app(AccentColor c, ValueChanged<String?> onChanged) =>
    ChangeNotifierProvider<SettingsProvider>.value(
      value: SettingsProvider.defaultSettings()
        ..update(accentColor: c, store: false),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: TintaDropdown<String>(
              value: 'a',
              items: const [
                DropdownMenuItem(value: 'a', child: Text('Világos')),
                DropdownMenuItem(value: 'b', child: Text('Sötét')),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('Üveg: picks on a glass sheet', (tester) async {
    String? got;
    await tester.pumpWidget(_app(AccentColor.uveg, (v) => got = v));
    expect(find.byType(DropdownButton<String>), findsNothing);
    await tester.tap(find.text('Világos'));
    await tester.pumpAndSettle();
    expect(find.byType(TintaSheetSurface), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.text('Sötét'));
    await tester.pumpAndSettle();
    expect(got, 'b');
    expect(find.byType(TintaSheetSurface), findsNothing);
  });

  testWidgets('Kobalt: the plain DropdownButton', (tester) async {
    await tester.pumpWidget(_app(AccentColor.kobalt, (_) {}));
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });
}
