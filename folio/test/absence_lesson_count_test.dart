import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:folio_mobile_ui/pages/absences/absences_page.dart';

Lesson _lesson(int index, DateTime start) => Lesson.fromJson({
      "Uid": "L$index",
      "Datum": DateTime(start.year, start.month, start.day).toIso8601String(),
      "KezdetIdopont": start.toIso8601String(),
      "VegIdopont": start.add(const Duration(minutes: 45)).toIso8601String(),
      "Oraszam": index,
      "TeremNeve": "1",
      "Tantargy": {"Uid": "S", "Nev": "Tárgy"},
    });

void main() {
  test('lessons that have not started do not count as held', () {
    final past = _lesson(1, DateTime(2026, 11, 9, 8));
    final next = _lesson(2, DateTime(2026, 11, 16, 8));
    expect(lessonsHeldBy([past, next], DateTime(2026, 11, 13)), [past]);
  });

  test('a lesson counts from its start', () {
    final now = _lesson(1, DateTime(2026, 11, 9, 8));
    expect(lessonsHeldBy([now], DateTime(2026, 11, 9, 8)), [now]);
  });
}
