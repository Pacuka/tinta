import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_wear/providers/wear_data_provider.dart';
import 'package:folio_wear/screens/wear_shell.dart';
import 'package:folio_wear/widgets/day_switcher.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

const _channel = MethodChannel('app.zan1456.folio.wear/data');

String _timetable(int count) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day, 8);
  return jsonEncode([
    for (var i = 0; i < count; i++)
      {
        'id': 'l$i',
        'subject': 'Tárgy $i',
        'room': '10$i',
        'teacher': 'Minta Tanár',
        'start': day.add(Duration(minutes: 50 * i)).millisecondsSinceEpoch,
        'end': day.add(Duration(minutes: 50 * i + 45)).millisecondsSinceEpoch,
        'lessonIndex': i + 1,
        'status': 'normal',
        'online': false,
      }
  ]);
}

Future<void> _pumpShell(WidgetTester tester, {int lessons = 12}) async {
  await initializeDateFormatting('hu');
  tester.view.physicalSize = const Size(454, 454);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    if (call.method == 'getCachedData') {
      return {
        'timetable': _timetable(lessons),
        'connected': true,
        'isPaired': true,
        'pairingCode': '123456',
      };
    }
    return null;
  });
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => WearDataProvider(),
    child: const MaterialApp(home: WearShell()),
  ));
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  testWidgets('vertical drag past the end keeps the page', (tester) async {
    await _pumpShell(tester);
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(WearShell), const Offset(0, -500));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('Nincs értesítés'), findsNothing);
    expect(find.text('Beállítások'), findsNothing);
  });

  testWidgets('the very first swipe scrolls the home page', (tester) async {
    await _pumpShell(tester);
    final scrollable = find.byType(Scrollable).last;
    final before = tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.drag(find.byType(WearShell), const Offset(0, -150));
    await tester.pump(const Duration(seconds: 1));
    final pos = tester.state<ScrollableState>(scrollable).position;
    final after = pos.pixels;
    expect(after, greaterThan(before + 100));
  });

  testWidgets('page dots sit inside the ring', (tester) async {
    await _pumpShell(tester);
    tester.view.physicalSize = const Size(227, 227);
    await tester.pump();
    final dots = tester.getRect(find.byKey(WearShell.pageDotsKey));
    // The ring takes the outer 14 points of the round screen.
    expect(dots.bottom, lessThanOrEqualTo(227 - 18));
  });

  group('next day switcher', () {
    String withTomorrow() {
      final list = (jsonDecode(_timetable(1)) as List).cast<Map>();
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day + 1, 8);
      return jsonEncode([
        ...list,
        {
          ...list.first,
          'id': 'next',
          'subject': 'Holnapi tárgy',
          'start': day.millisecondsSinceEpoch,
          'end': day.add(const Duration(minutes: 45)).millisecondsSinceEpoch,
        },
      ]);
    }

    Future<void> fromNative(String method, Object? args) async {
      final data = const StandardMethodCodec()
          .encodeMethodCall(MethodCall(method, args));
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(_channel.name, data, (_) {});
    }

    Future<void> openNextDay(WidgetTester tester) async {
      await fromNative('onTimetableReceived', withTomorrow());
      await tester.pump();
      WearDataProvider.onRotaryInput!(12.0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Holnap'));
      await tester.pump();
    }

    testWidgets('shows the next school day on tap', (tester) async {
      await _pumpShell(tester);
      await openNextDay(tester);
      expect(find.text('Holnapi tárgy'), findsOneWidget);
    });

    testWidgets('no known next day hides the switcher', (tester) async {
      await _pumpShell(tester, lessons: 1);
      WearDataProvider.onRotaryInput!(12.0);
      await tester.pumpAndSettle();
      expect(find.byType(DaySwitcher), findsNothing);
    });

    testWidgets('choice is dropped when the next day goes away',
        (tester) async {
      await _pumpShell(tester);
      await openNextDay(tester);
      await fromNative('onTimetableReceived', _timetable(1));
      await tester.pump();
      await fromNative('onTimetableReceived', withTomorrow());
      await tester.pump();
      expect(find.text('Holnapi tárgy'), findsNothing);
    });
  });

  testWidgets('one bezel step moves a small part of the screen',
      (tester) async {
    await _pumpShell(tester);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).last).position;
    WearDataProvider.onRotaryInput!(1.0);
    await tester.pumpAndSettle();
    expect(position.pixels, inInclusiveRange(1.0, 60.0));
  });

  testWidgets('quick bezel steps add up', (tester) async {
    await _pumpShell(tester);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable).last).position;
    for (var i = 0; i < 3; i++) {
      WearDataProvider.onRotaryInput!(1.0);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    final oneStep = WearShellTuning.crownStep;
    expect(position.pixels, closeTo(oneStep * 3, 0.5));
  });

  testWidgets('crown past the end keeps the page', (tester) async {
    await _pumpShell(tester);
    for (var i = 0; i < 20; i++) {
      WearDataProvider.onRotaryInput!(5.0);
      await tester.pump(const Duration(milliseconds: 800));
    }
    expect(find.text('Nincs értesítés'), findsNothing);
    expect(find.text('Beállítások'), findsNothing);
  });

  testWidgets('horizontal drag changes page', (tester) async {
    await _pumpShell(tester);
    await tester.fling(
        find.byType(WearShell), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Frissítsd a Tintát a telefonon'), findsOneWidget);

    await tester.fling(
        find.byType(WearShell), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Nincs értesítés'), findsOneWidget);

    await tester.fling(
        find.byType(WearShell), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Beállítások'), findsOneWidget);
  });

  Future<int> countExits(WidgetTester tester, Offset drag) async {
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exits++;
      return null;
    });
    await tester.drag(find.byType(WearShell), drag);
    await tester.pump(const Duration(seconds: 1));
    return exits;
  }

  testWidgets('swipe right on the first page leaves the app', (tester) async {
    await _pumpShell(tester);
    expect(await countExits(tester, const Offset(300, 0)), 1);
  });

  testWidgets('a diagonal drag stays in the app', (tester) async {
    await _pumpShell(tester);
    expect(await countExits(tester, const Offset(120, 100)), 0);
  });

  testWidgets('a small sideways nudge stays in the app', (tester) async {
    await _pumpShell(tester);
    expect(await countExits(tester, const Offset(40, 0)), 0);
  });

  testWidgets('swipe right on a later page goes back', (tester) async {
    await _pumpShell(tester);
    await tester.fling(find.byType(WearShell), const Offset(-300, 0), 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(await countExits(tester, const Offset(300, 0)), 0);
  });

  testWidgets('crown works without a scrollable page', (tester) async {
    await _pumpShell(tester, lessons: 0);
    WearDataProvider.onRotaryInput!(5.0);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('Beállítások'), findsNothing);
  });
}
