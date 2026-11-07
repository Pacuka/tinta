import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_wear/models/wear_lesson.dart';
import 'package:folio_wear/widgets/home_ring.dart';
import 'package:intl/date_symbol_data_local.dart';

WearLesson lesson(String subject, String room, DateTime start, int index) =>
    WearLesson(
      id: subject,
      subject: subject,
      room: room,
      teacher: 'Minta Tanár',
      start: start,
      end: start.add(const Duration(minutes: 45)),
      lessonIndex: index,
      status: 'normal',
      online: false,
    );

DateTime t(int h, int m) => DateTime(2026, 11, 9, h, m);

final _day = [
  lesson('Történelem', '12', t(8, 0), 3),
  lesson('Angol', '305', t(9, 0), 4),
];

Future<void> _pump(WidgetTester tester, List<WearLesson> lessons,
    DateTime Function() clock,
    {Size size = const Size(227, 227), VoidCallback? onRefresh}) async {
  await initializeDateFormatting('hu');
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: HomeRing(lessons: lessons, clock: clock, onRefresh: onRefresh),
      ),
    ),
  ));
}

void main() {
  testWidgets('in lesson', (tester) async {
    await _pump(tester, _day, () => t(8, 21));
    expect(find.text('3. óra'), findsOneWidget);
    expect(find.text('Történelem'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Utána: Angol, 305'), findsOneWidget);
  });

  testWidgets('break', (tester) async {
    await _pump(tester, _day, () => t(8, 50));
    expect(find.text('Szünet'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Angol'), findsOneWidget);
    expect(find.text('305'), findsOneWidget);
  });

  testWidgets('before first, far away shows the start time', (tester) async {
    await _pump(tester, _day, () => t(6, 0));
    expect(find.text('Első óra'), findsOneWidget);
    expect(find.text('Történelem'), findsOneWidget);
    expect(find.text('8:00'), findsOneWidget);
  });

  testWidgets('before first, within an hour shows minutes', (tester) async {
    await _pump(tester, _day, () => t(7, 30));
    expect(find.text('30'), findsOneWidget);
    expect(find.text('8:00'), findsNothing);
  });

  testWidgets('done without known lesson', (tester) async {
    await _pump(tester, _day, () => t(15, 0));
    expect(find.text('Mára végeztél'), findsOneWidget);
    expect(find.textContaining('első óra'), findsNothing);
    expect(find.textContaining('Következő'), findsNothing);
  });

  testWidgets('done with lesson tomorrow', (tester) async {
    final tomorrow = lesson('Matematika', '101', DateTime(2026, 11, 10, 8), 1);
    await _pump(tester, [..._day, tomorrow], () => t(15, 0));
    expect(find.text('Holnap első óra'), findsOneWidget);
    expect(find.text('8:00 · Matematika'), findsOneWidget);
  });

  testWidgets('no lessons, known lesson later this week', (tester) async {
    final later = lesson('Matematika', '101', DateTime(2026, 11, 12, 8), 1);
    await _pump(tester, [later], () => t(15, 0));
    expect(find.text('Ma nincs órád'), findsOneWidget);
    expect(find.text('Következő óra'), findsOneWidget);
    expect(find.text('csütörtök 8:00 · Matematika'), findsOneWidget);
  });

  testWidgets('no lessons offers a refresh', (tester) async {
    var asked = 0;
    await _pump(tester, const [], () => t(15, 0), onRefresh: () => asked++);
    await tester.tap(find.text('Frissítés'));
    expect(asked, 1);
  });

  for (final size in const [Size(192, 192), Size(227, 227)]) {
    testWidgets('long names fit at ${size.width}', (tester) async {
      final name = 'Nagyon hosszú tantárgynév ' * 3;
      final long = [
        lesson(name, name, t(8, 0), 3),
        lesson(name, name, t(9, 0), 4),
      ];
      await _pump(tester, long, () => t(8, 21), size: size);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(192, 192), Size(227, 227)]) {
    testWidgets('long subject wraps instead of cutting at ${size.width}',
        (tester) async {
      const name = 'Informatika és digitális kultúra';
      await _pump(tester, [lesson(name, '12', t(8, 0), 3)], () => t(8, 21),
          size: size);
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(name));
      expect(text.maxLines, 2);
      expect(text.style!.fontSize, 15.0);
    });
  }

  testWidgets('refreshes each minute', (tester) async {
    var now = t(8, 21);
    await _pump(tester, _day, () => now);
    now = t(8, 22);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('23'), findsOneWidget);
  });

  testWidgets('refreshes on resume', (tester) async {
    var now = t(8, 21);
    await _pump(tester, _day, () => now);
    now = t(8, 40);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('5'), findsOneWidget);
  });
}
