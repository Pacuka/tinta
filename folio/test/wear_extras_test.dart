import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:folio/api/providers/wear_extras.dart';
import 'package:folio_kreta_api/models/category.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio_kreta_api/models/week.dart';

void main() {
  final monday = DateTime(2026, 11, 9, 12);

  WearTodoItem item(String id, DateTime due, {String type = 'homework'}) =>
      WearTodoItem(id: id, type: type, subject: 'Tárgy', due: due);

  List decodeTodos(String json) => jsonDecode(json)['todos'] as List;

  test('keeps the next seven days', () {
    final json = buildWearExtras(
      items: [
        item('ma', DateTime(2026, 11, 9, 8)),
        item('hetedik', DateTime(2026, 11, 16, 8)),
        item('nyolcadik', DateTime(2026, 11, 17, 8)),
      ],
      average: 4.0,
      now: monday,
    );
    expect(decodeTodos(json).map((t) => t['id']), ['ma', 'hetedik']);
  });

  test('drops past items', () {
    final json = buildWearExtras(
      items: [item('tegnap', DateTime(2026, 11, 8, 23))],
      average: null,
      now: monday,
    );
    expect(decodeTodos(json), isEmpty);
  });

  test('limits to fifteen sorted by date', () {
    final json = buildWearExtras(
      items: [
        for (var i = 20; i > 0; i--)
          item('$i', DateTime(2026, 11, 9, 8).add(Duration(hours: i))),
      ],
      average: null,
      now: monday,
    );
    final todos = decodeTodos(json);
    expect(todos.length, 15);
    expect(todos.first['id'], '1');
    expect(todos.last['id'], '15');
  });

  test('null average stays null and zero means no grades', () {
    expect(
        jsonDecode(buildWearExtras(items: [], average: null, now: monday))[
            'average'],
        isNull);
    expect(
        jsonDecode(buildWearExtras(items: [], average: 0, now: monday))[
            'average'],
        isNull);
  });

  test('average is rounded to two decimals', () {
    expect(
        jsonDecode(buildWearExtras(items: [], average: 4.3333, now: monday))[
            'average'],
        4.33);
  });

  test('study average uses rounded subject marks', () {
    // 4.5 rounds up at a 0.5 threshold, 3.4 stays 3: (5 + 3) / 2.
    expect(
        wearStudyAverage([
          (average: 4.5, threshold: 0.5),
          (average: 3.4, threshold: 0.5),
        ]),
        4.0);
  });

  test('study average honours a subject threshold', () {
    expect(wearStudyAverage([(average: 4.3, threshold: 0.2)]), 5.0);
  });

  test('study average without subjects is zero', () {
    expect(wearStudyAverage(const []), 0.0);
  });

  test('uses renamed subjects', () {
    final s = GradeSubject(
        id: '1', category: Category(id: '1'), name: 'Matematika')
      ..renamedTo = 'Matek';
    expect(wearSubjectName(s), 'Matek');
    s.renamedTo = '';
    expect(wearSubjectName(s), 'Matematika');
  });

  test('next week from friday', () {
    expect(needsNextWeek(DateTime(2026, 11, 12)), isFalse); // Thursday
    expect(needsNextWeek(DateTime(2026, 11, 13)), isTrue); // Friday
    expect(needsNextWeek(DateTime(2026, 11, 15)), isTrue); // Sunday
    expect(needsNextWeek(DateTime(2026, 11, 16)), isFalse); // Monday
  });

  test('fetches next week only when needed', () async {
    final asked = <Week>[];
    await fetchNextWeekIfNeeded(DateTime(2026, 11, 12), (w) async => asked.add(w));
    expect(asked, isEmpty);
    await fetchNextWeekIfNeeded(DateTime(2026, 11, 13), (w) async => asked.add(w));
    expect(asked.single.start.day, 16);
  });

  test('failed next week keeps sync going', () async {
    await fetchNextWeekIfNeeded(
        DateTime(2026, 11, 13), (_) async => throw Exception('nincs net'));
  });
}
