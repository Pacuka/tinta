import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_kreta_api/models/exam.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/widgets/exam/exam_viewable.dart';
import 'package:folio_mobile_ui/common/widgets/homework/homework_view.dart';
import 'package:folio_mobile_ui/common/widgets/homework/homework_viewable.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

Homework _homework(String text) => Homework.fromJson({
      "Uid": "1",
      "Szoveg": text,
      "Tantargy": {"Uid": "s1", "Nev": "Magyar nyelv és irodalom"},
    });

Exam _exam(String text) => Exam.fromJson({
      "Uid": "2",
      "Temaja": text,
      "Tantargy": {"Uid": "s2", "Nev": "Történelem"},
      "Modja": {
        "Uid": "1",
        "Nev": "irasbeli_dolgozat",
        "Leiras": "Írásbeli dolgozat"
      },
    });

/// Opens [popup] in the same sheet the app uses, on a phone-sized screen.
Future<void> _open(WidgetTester tester, Widget Function(BuildContext) popup,
    {Size size = const Size(360, 640), double textScale = 1.0}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<SettingsProvider>.value(
    value: SettingsProvider.defaultSettings(),
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: I18n(
          initialLocale: const Locale('hu', 'HU'),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showRoundedModalBottomSheet(
              context,
              child: popup(context),
              showHandle: false,
            ),
            child: const Text("nyit"),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text("nyit"));
  await tester.pumpAndSettle();
}

void _expectEndReachable(WidgetTester tester, String end) {
  expect(tester.takeException(), isNull);
  // a scrollable (and not only the text field's own one) holds the content
  final found = find.textContaining(end, findRichText: true);
  expect(found, findsOneWidget);
  final scroll = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(SingleChildScrollView));
  expect(scroll, findsWidgets);
}

void main() {
  setUpAll(() => initializeDateFormatting("hu_HU"));

  final long = "${'Hasonlítsa össze Vladimir és Estragon párbeszédét. ' * 60}"
      "VÉGE-A-SZÖVEGNEK";

  for (final (name, scale) in [("normál betű", 1.0), ("nagy betű", 1.5)]) {
    testWidgets('homework popup: long text scrolls to the end ($name)',
        (tester) async {
      await _open(
          tester,
          (ctx) =>
              HomeworkPopup(homework: _homework(long), outsideContext: ctx),
          textScale: scale);
      _expectEndReachable(tester, "VÉGE-A-SZÖVEGNEK");
    });

    testWidgets('homework view: long text scrolls to the end ($name)',
        (tester) async {
      await _open(tester, (ctx) => HomeworkView(_homework(long)),
          textScale: scale);
      _expectEndReachable(tester, "VÉGE-A-SZÖVEGNEK");
    });

    testWidgets('exam popup: long text scrolls to the end ($name)',
        (tester) async {
      await _open(
          tester, (ctx) => ExamPopup(exam: _exam(long), outsideContext: ctx),
          textScale: scale);
      _expectEndReachable(tester, "VÉGE-A-SZÖVEGNEK");
    });
  }

  testWidgets('homework popup: dragging on the text scrolls it',
      (tester) async {
    await _open(tester,
        (ctx) => HomeworkPopup(homework: _homework(long), outsideContext: ctx));
    final scrollable = tester.state<ScrollableState>(find
        .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable))
        .first);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    await tester.drag(find.byType(HomeworkPopup), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(find.byType(HomeworkPopup), findsOneWidget);
  });

  testWidgets('homework popup: pulling down at the top closes it',
      (tester) async {
    await _open(tester,
        (ctx) => HomeworkPopup(homework: _homework(long), outsideContext: ctx));
    await tester.drag(find.byType(HomeworkPopup), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.byType(HomeworkPopup), findsNothing);
  });

  testWidgets('homework popup: pulling down mid-text only scrolls back',
      (tester) async {
    await _open(tester,
        (ctx) => HomeworkPopup(homework: _homework(long), outsideContext: ctx));
    await tester.drag(find.byType(HomeworkPopup), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(HomeworkPopup), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.byType(HomeworkPopup), findsOneWidget);
  });

  testWidgets('homework popup: shows earlier versions on tap', (tester) async {
    final json = {
      "Uid": "1",
      "Szoveg": "Új szöveg.",
      "Tantargy": {"Uid": "s1", "Nev": "Magyar nyelv és irodalom"},
    };
    Homework.carryModified({...json, "Szoveg": "Régi szöveg."}, json,
        now: DateTime(2026, 11, 4, 21, 30));
    final hw = Homework.fromJson(json);
    await _open(
        tester, (ctx) => HomeworkPopup(homework: hw, outsideContext: ctx));
    expect(find.textContaining("Módosítva: "), findsOneWidget);
    expect(find.text("Régi szöveg."), findsNothing);
    await tester.tap(find.byKey(const Key("homework-history")));
    await tester.pumpAndSettle();
    expect(find.text("Régi szöveg."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('homework popup: short text keeps the sheet small',
      (tester) async {
    await _open(
        tester,
        (ctx) =>
            HomeworkPopup(homework: _homework("Rövid."), outsideContext: ctx));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(HomeworkPopup)).height, lessThan(500));
  });
}
