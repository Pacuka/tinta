import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

SettingsProvider _settings(AccentColor c) =>
    SettingsProvider.defaultSettings()..update(accentColor: c, store: false);

Widget _app(AccentColor c, Widget child, {EdgeInsets? viewInsets}) =>
    ChangeNotifierProvider<SettingsProvider>.value(
      value: _settings(c),
      child: MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: viewInsets ?? EdgeInsets.zero),
            child: Scaffold(
              body: Align(alignment: Alignment.bottomCenter, child: child),
            ),
          ),
        ),
      ),
    );

const _body = SizedBox(height: 80, child: Text('Tartalom'));

void main() {
  testWidgets('Üveg: a solid lit panel, NOT live glass (120 Hz perf)',
      (tester) async {
    // Live glass on a sheet this big cost ~7 ms/frame on the Redmi and the
    // open animation stuttered (2026-11-16).
    await tester.pumpWidget(
        _app(AccentColor.uveg, const RoundedBottomSheet(child: _body)));
    expect(find.byType(AdaptiveGlass), findsNothing);
    expect(find.text('Tartalom'), findsOneWidget);
    final panel = tester.widget<DecoratedBox>(find
        .descendant(
            of: find.byType(RoundedBottomSheet),
            matching: find.byType(DecoratedBox))
        .first);
    final color = (panel.decoration as BoxDecoration).color!;
    // solid: without blur any see-through ghosted the text behind
    expect(color.a, 1.0);
  });

  testWidgets('Kobalt keeps the solid scaffold-coloured sheet',
      (tester) async {
    await tester.pumpWidget(
        _app(AccentColor.kobalt, const RoundedBottomSheet(child: _body)));
    expect(find.byType(AdaptiveGlass), findsNothing);
    final box = tester.widget<Container>(find
        .descendant(
            of: find.byType(RoundedBottomSheet),
            matching: find.byType(Container))
        .first);
    final context = tester.element(find.byType(RoundedBottomSheet));
    expect((box.decoration as BoxDecoration).color,
        Theme.of(context).scaffoldBackgroundColor);
  });

  testWidgets('Üveg: an explicit backgroundColor still wins', (tester) async {
    await tester.pumpWidget(_app(
        AccentColor.uveg,
        const RoundedBottomSheet(
            backgroundColor: Colors.red, child: _body)));
    expect(find.byType(AdaptiveGlass), findsNothing);
  });

  testWidgets('Üveg: a field padded by viewInsets stays above the keyboard',
      (tester) async {
    await tester.pumpWidget(_app(
      AccentColor.uveg,
      Builder(
        builder: (context) => RoundedBottomSheet(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: const TextField(),
          ),
        ),
      ),
      viewInsets: const EdgeInsets.only(bottom: 300),
    ));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getRect(find.byType(TextField)).bottom,
        lessThanOrEqualTo(screen.height - 300));
  });
}
