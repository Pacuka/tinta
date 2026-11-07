import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_wear/models/wear_extras.dart';
import 'package:folio_wear/providers/wear_data_provider.dart';
import 'package:folio_wear/screens/notifications_screen.dart';
import 'package:folio_wear/screens/todos_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

const _channel = MethodChannel('app.zan1456.folio.wear/data');

String extrasJson(List<Map<String, Object?>> todos, {double? average}) =>
    jsonEncode({'average': average, 'todos': todos});

Map<String, Object?> todo(String subject, DateTime due,
        {String type = 'homework'}) =>
    {
      'id': subject,
      'type': type,
      'subject': subject,
      'due': due.millisecondsSinceEpoch,
    };

void main() {
  final monday = DateTime(2026, 11, 9, 12);

  test('parses a full message', () {
    final e = WearExtras.tryParse(extrasJson(
        [todo('Matek', DateTime(2026, 11, 10), type: 'exam')],
        average: 4.32))!;
    expect(e.average, 4.32);
    expect(e.todos.single.subject, 'Matek');
    expect(e.todos.single.type, 'exam');
    expect(e.todos.single.due, DateTime(2026, 11, 10));
  });

  test('broken json gives null', () {
    expect(WearExtras.tryParse('nem json'), isNull);
    expect(WearExtras.tryParse('{"todos": 5}'), isNull);
    expect(WearExtras.tryParse('[]'), isNull);
  });

  test('missing average is null', () {
    expect(WearExtras.tryParse('{"todos": []}')!.average, isNull);
  });

  test('past todos are filtered, today stays', () {
    final e = WearExtras.tryParse(extrasJson([
      todo('Tegnapi', DateTime(2026, 11, 8, 23)),
      todo('Mai', DateTime(2026, 11, 9, 8)),
    ]))!;
    expect(e.upcoming(monday).map((t) => t.subject), ['Mai']);
  });

  group('screens', () {
    late Map<String, Object?> cached;

    setUp(() {
      cached = {'connected': true, 'isPaired': true, 'pairingCode': '123456'};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        if (call.method == 'getCachedData') return cached;
        return null;
      });
    });

    Future<void> fromNative(String method, Object? args) async {
      final data = const StandardMethodCodec()
          .encodeMethodCall(MethodCall(method, args));
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(_channel.name, data, (_) {});
    }

    Future<void> pump(WidgetTester tester, Widget child) async {
      await initializeDateFormatting('hu');
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => WearDataProvider(),
        child: MaterialApp(home: Scaffold(body: child)),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    }

    Widget todos() => TodosScreen(scrollController: ScrollController());

    testWidgets('no extras asks to update the phone', (tester) async {
      await pump(tester, todos());
      expect(find.text('Frissítsd a Tintát a telefonon'), findsOneWidget);
    });

    testWidgets('empty list says nothing to do', (tester) async {
      cached['extras'] = extrasJson([]);
      await pump(tester, todos());
      expect(find.text('Nincs teendő a következő 7 napban'), findsOneWidget);
    });

    testWidgets('todos show day labels', (tester) async {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day);
      cached['extras'] = extrasJson([
        todo('Mai tárgy', day.add(const Duration(hours: 20))),
        todo('Holnapi tárgy', day.add(const Duration(days: 1, hours: 8))),
      ]);
      await pump(tester, todos());
      expect(find.text('Teendők'), findsOneWidget);
      expect(find.text('Mai tárgy'), findsOneWidget);
      expect(find.text('Ma'), findsOneWidget);
      expect(find.text('Holnap'), findsOneWidget);
    });

    testWidgets('broken message keeps previous data', (tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      cached['extras'] = extrasJson([todo('Megmarad', tomorrow)]);
      await pump(tester, todos());
      await fromNative('onExtrasReceived', 'hibás');
      await tester.pump();
      expect(find.text('Megmarad'), findsOneWidget);
    });

    testWidgets('new message replaces the list', (tester) async {
      await pump(tester, todos());
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await fromNative('onExtrasReceived', extrasJson([todo('Új', tomorrow)]));
      await tester.pump();
      expect(find.text('Új'), findsOneWidget);
    });

    testWidgets('average line uses a decimal comma', (tester) async {
      cached
        ..['extras'] = extrasJson([], average: 4.3)
        ..['notifications'] = jsonEncode([
          {
            'id': 'g',
            'title': 'Matek',
            'body': 'Jeles',
            'type': 'grade',
            'gradeValue': 5,
            'timestamp': DateTime(2026, 11, 9).millisecondsSinceEpoch,
          }
        ]);
      await pump(tester,
          NotificationsScreen(scrollController: ScrollController()));
      expect(find.text('Tanulmányi átlag: 4,30'), findsOneWidget);
    });

    testWidgets('no average, no line', (tester) async {
      cached['notifications'] = jsonEncode([
        {
          'id': 'g',
          'title': 'Matek',
          'body': 'Jeles',
          'type': 'grade',
          'gradeValue': 5,
          'timestamp': DateTime(2026, 11, 9).millisecondsSinceEpoch,
        }
      ]);
      await pump(tester,
          NotificationsScreen(scrollController: ScrollController()));
      expect(find.textContaining('Átlag'), findsNothing);
    });
  });
}
