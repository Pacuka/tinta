import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio_mobile_ui/common/tinta_confirm.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

bool? result;

Widget _app(AccentColor? c, {String? cancel = 'Mégse'}) {
  final app = MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showTintaConfirm(
              context,
              title: 'Törlöd?',
              message: 'Nem vonható vissza.',
              confirmLabel: 'Törlés',
              cancelLabel: cancel,
              destructive: true,
              fallback: (ctx) => AlertDialog(
                title: const Text('Törlöd?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Mégse')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Törlés')),
                ],
              ),
            );
          },
          child: const Text('nyit'),
        ),
      ),
    ),
  );
  if (c == null) return app;
  return ChangeNotifierProvider<SettingsProvider>.value(
    value: SettingsProvider.defaultSettings()
      ..update(accentColor: c, store: false),
    child: app,
  );
}

Future<void> _open(WidgetTester tester, Widget app) async {
  result = null;
  await tester.pumpWidget(app);
  await tester.tap(find.text('nyit'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Kobalt: the original AlertDialog, confirm → true',
      (tester) async {
    await _open(tester, _app(AccentColor.kobalt));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Törlés'));
    await tester.pumpAndSettle();
    expect(result, true);
  });

  testWidgets('Kobalt: cancel → false', (tester) async {
    await _open(tester, _app(AccentColor.kobalt));
    await tester.tap(find.text('Mégse'));
    await tester.pumpAndSettle();
    expect(result, false);
  });

  testWidgets('no SettingsProvider in the tree: falls back, no crash',
      (tester) async {
    await _open(tester, _app(null));
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('Üveg + Android: glass dialog, confirm → true', (tester) async {
    await _open(tester, _app(AccentColor.uveg));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(GlassDialog), findsOneWidget);
    // a Material inside the dialog route gives the app's text style
    // (without it: yellow underline + monospace on the phone)
    expect(
        find.ancestor(
            of: find.byType(GlassDialog), matching: find.byType(Material)),
        findsWidgets);
    await tester.tap(find.text('Törlés'));
    await tester.pumpAndSettle();
    expect(result, true);
  });

  testWidgets('Üveg + Android: cancel → false', (tester) async {
    await _open(tester, _app(AccentColor.uveg));
    await tester.tap(find.text('Mégse'));
    await tester.pumpAndSettle();
    expect(result, false);
  });

  testWidgets('Üveg + Android: single button (no cancel)', (tester) async {
    await _open(tester, _app(AccentColor.uveg, cancel: null));
    expect(find.text('Mégse'), findsNothing);
    await tester.tap(find.text('Törlés'));
    await tester.pumpAndSettle();
    expect(result, true);
  });

  group('Üveg + iPhone: native alert', () {
    const channel = MethodChannel('cn_alert');
    Map<Object?, Object?>? sent;

    Future<void> run(WidgetTester tester, Object? reply) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        sent = call.arguments as Map<Object?, Object?>;
        return reply;
      });
      await _open(tester, _app(AccentColor.uveg));
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    }

    testWidgets('confirm (index 1) → true, two actions sent', (tester) async {
      await run(tester, {'index': 1});
      expect(result, true);
      expect(sent!['title'], 'Törlöd?');
      expect((sent!['actions'] as List).length, 2);
    });

    testWidgets('no answer (null) → false', (tester) async {
      await run(tester, null);
      expect(result, false);
    });
  });
}
