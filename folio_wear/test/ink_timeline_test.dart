import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_wear/models/wear_lesson.dart';
import 'package:folio_wear/theme/wear_theme.dart';
import 'package:folio_wear/widgets/ink_blot.dart';
import 'package:folio_wear/widgets/ink_timeline.dart';
import 'package:intl/date_symbol_data_local.dart';

WearLesson lesson(
  String subject,
  DateTime start, {
  String status = 'normal',
  String teacher = 'Minta Tanár',
  String room = '101',
  bool homework = false,
  bool exam = false,
  bool online = false,
}) =>
    WearLesson(
      id: subject,
      subject: subject,
      room: room,
      teacher: teacher,
      start: start,
      end: start.add(const Duration(minutes: 45)),
      lessonIndex: 1,
      status: status,
      online: online,
      hasHomework: homework,
      hasExam: exam,
    );

DateTime t(int h, int m) => DateTime(2026, 11, 9, h, m);

Future<void> _pump(WidgetTester tester, List<WearLesson> lessons,
    {Size size = const Size(227, 227), DateTime? now, DateTime? day}) async {
  await initializeDateFormatting('hu');
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: InkTimeline(lessons: lessons, now: now ?? t(8, 21), day: day),
      ),
    ),
  ));
}

void main() {
  testWidgets('cancelled lesson', (tester) async {
    await _pump(tester, [lesson('Testnevelés', t(9, 0), status: 'cancelled')]);
    final title = tester.widget<Text>(find.text('Testnevelés'));
    expect(title.style!.decoration, TextDecoration.lineThrough);
    expect(find.text('Elmarad'), findsOneWidget);
  });

  testWidgets('all cancelled still listed', (tester) async {
    await _pump(tester, [
      lesson('Testnevelés', t(9, 0), status: 'cancelled'),
      lesson('Rajz', t(10, 0), status: 'cancelled'),
    ]);
    expect(find.text('Testnevelés'), findsOneWidget);
    expect(find.text('Rajz'), findsOneWidget);
  });

  testWidgets('substitute', (tester) async {
    await _pump(tester, [
      lesson('Informatika', t(9, 0),
          status: 'substitution', teacher: 'Helyettes Vera'),
    ]);
    expect(find.text('Helyettes Vera'), findsOneWidget);
  });

  testWidgets('current lesson', (tester) async {
    await _pump(tester, [lesson('Történelem', t(8, 0), room: '12')]);
    expect(find.text('még 24 perc · 12'), findsOneWidget);
  });

  BoxDecoration? cardOf(WidgetTester tester, String subject) {
    final boxes = tester.widgetList<DecoratedBox>(find.ancestor(
        of: find.text(subject), matching: find.byType(DecoratedBox)));
    for (final b in boxes) {
      final d = b.decoration;
      if (d is BoxDecoration && d.color == WearColors.cobalt) return d;
    }
    return null;
  }

  testWidgets('only the current lesson gets the card', (tester) async {
    await _pump(tester, [
      lesson('Történelem', t(8, 0)),
      lesson('Angol', t(9, 0)),
    ]);
    expect(cardOf(tester, 'Történelem'), isNotNull);
    expect(cardOf(tester, 'Angol'), isNull);
  });

  testWidgets('the line ends with the end of the school day', (tester) async {
    await _pump(tester, [
      lesson('Történelem', t(8, 0)),
      lesson('Angol', t(9, 0)),
      lesson('Rajz', t(10, 0), status: 'cancelled'),
    ]);
    expect(find.text('Vége: 9:45'), findsOneWidget);
    expect(find.byType(InkBlot), findsOneWidget);
  });

  testWidgets('no end mark when nothing is held today', (tester) async {
    await _pump(tester, [lesson('Rajz', t(10, 0), status: 'cancelled')]);
    expect(find.textContaining('Vége'), findsNothing);
  });

  testWidgets('no end mark on the weekly list', (tester) async {
    await _pump(tester, [lesson('Rajz', DateTime(2026, 11, 10, 8))]);
    expect(find.textContaining('Vége'), findsNothing);
  });

  testWidgets('timeline shows the chosen day', (tester) async {
    await _pump(tester, [
      lesson('Történelem', t(8, 0)),
      lesson('Holnapi', DateTime(2026, 11, 10, 8)),
    ], day: DateTime(2026, 11, 10));
    expect(find.text('Holnapi'), findsOneWidget);
    expect(find.text('Történelem'), findsNothing);
    expect(find.text('Vége: 8:45'), findsOneWidget);
  });

  testWidgets('normal lesson shows time and room', (tester) async {
    await _pump(tester, [lesson('Angol', t(9, 0), room: '305')]);
    expect(find.text('9:00 · 305'), findsOneWidget);
  });

  testWidgets('homework and exam icons', (tester) async {
    await _pump(
        tester, [lesson('Angol', t(9, 0), homework: true, exam: true)]);
    expect(find.byIcon(Icons.assignment_rounded), findsOneWidget);
    expect(find.byIcon(Icons.quiz_rounded), findsOneWidget);
  });

  testWidgets('online lesson icon', (tester) async {
    await _pump(tester, [lesson('Angol', t(9, 0), online: true)]);
    expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
  });

  testWidgets('no lessons today shows the next school day only',
      (tester) async {
    await _pump(tester, [
      lesson('Múltheti', DateTime(2026, 11, 2, 8)),
      lesson('Matematika', DateTime(2026, 11, 10, 8)),
      lesson('Angol', DateTime(2026, 11, 11, 8)),
    ]);
    expect(find.text('kedd'), findsOneWidget);
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Angol'), findsNothing);
    expect(find.text('Múltheti'), findsNothing);
  });

  testWidgets('stale data lists nothing', (tester) async {
    await _pump(tester, [lesson('Múltheti', DateTime(2026, 11, 2, 8))]);
    expect(find.text('Múltheti'), findsNothing);
  });

  testWidgets('long names fit', (tester) async {
    final name = 'Nagyon hosszú tantárgynév ' * 3;
    await _pump(
        tester,
        [
          lesson(name, t(8, 0), room: name),
          lesson(name, t(9, 0), status: 'substitution', teacher: name),
        ],
        size: const Size(192, 192));
    expect(tester.takeException(), isNull);
  });
}
