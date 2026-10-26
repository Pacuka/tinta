import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_kreta_api/models/exam.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:folio_mobile_ui/common/widgets/exam/exam_tile.dart';
import 'package:folio_mobile_ui/common/widgets/homework/homework_tile.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider<SettingsProvider>.value(
      value: SettingsProvider.defaultSettings(),
      child: MaterialApp(
        home: I18n(
          initialLocale: const Locale('hu', 'HU'),
          child: Scaffold(
            body: Center(child: SizedBox(width: 360, child: child)),
          ),
        ),
      ),
    );

Homework _homework(String text) => Homework.fromJson({
      "Uid": "1",
      "Szoveg": text,
      "Tantargy": {"Uid": "s1", "Nev": "Magyar nyelv és irodalom"},
    });

Exam _exam(String text) => Exam.fromJson({
      "Uid": "2",
      "Temaja": text,
      "Tantargy": {"Uid": "s2", "Nev": "Történelem"},
      "Modja": {"Uid": "1", "Nev": "irasbeli_dolgozat", "Leiras": "Írásbeli dolgozat"},
    });

Text _titleText(WidgetTester tester, String startsWith) => tester
    .widgetList<Text>(find.byType(Text))
    .firstWhere((t) => (t.data ?? '').startsWith(startsWith));

void main() {
  final long = 'Olvassák el és tanulják meg a verset ' * 9; // ~300 karakter

  testWidgets('homework: long title wraps to 2 lines, shows Házi tag',
      (tester) async {
    await tester.pumpWidget(_wrap(HomeworkTile(_homework(long))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(_titleText(tester, 'Olvassák').maxLines, 2);
    expect(find.text('Házi'), findsOneWidget);
  });

  testWidgets('homework: empty title does not throw', (tester) async {
    await tester.pumpWidget(_wrap(HomeworkTile(_homework(''))));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('exam: long title wraps to 2 lines, shows Dolgozat tag',
      (tester) async {
    await tester.pumpWidget(_wrap(ExamTile(_exam(long))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Dolgozat'), findsOneWidget);
  });
}
