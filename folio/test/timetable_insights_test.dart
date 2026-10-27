import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/timetable_insights.dart';
import 'package:folio_kreta_api/models/lesson.dart';

String _iso(DateTime d) => d.toIso8601String();

Lesson _lesson(DateTime start, DateTime end, {String subject = "Matematika"}) =>
    Lesson.fromJson({
      "Uid": "L${_iso(start)}",
      "Datum": _iso(DateTime(start.year, start.month, start.day)),
      "KezdetIdopont": _iso(start),
      "VegIdopont": _iso(end),
      "Oraszam": 1,
      "Tantargy": {"Uid": "S-$subject", "Nev": subject},
    });

/// KRÉTA's non-school-day entry: no subject, midnight times, a name.
Lesson _breakDay(DateTime day, {String name = "Őszi szünet (Nem órarendi nap) (Szerda)"}) =>
    Lesson.fromJson({
      "Uid": "B${_iso(day)}",
      "Datum": _iso(day),
      "KezdetIdopont": _iso(day),
      "VegIdopont": _iso(day),
      "Nev": name,
    });

void main() {
  final mon = DateTime(2026, 10, 26);
  DateTime d(int offset) => mon.add(Duration(days: offset));
  List<List<Lesson>> breakWeek() =>
      List.generate(5, (i) => [_breakDay(d(i))]);

  test('breakName strips parenthesised parts', () {
    expect(breakName("Őszi szünet (Nem órarendi nap) (Szerda)"), "Őszi szünet");
  });

  test('isNonSchoolDay', () {
    expect(isNonSchoolDay([_breakDay(mon)]), isTrue);
    expect(isNonSchoolDay([_lesson(d(0).add(const Duration(hours: 8)), d(0).add(const Duration(hours: 9)))]), isFalse);
    expect(isNonSchoolDay([]), isFalse);
  });

  test('span over the whole week, days left from Tuesday', () {
    final s = breakSpanFor(breakWeek(), 2, d(1).add(const Duration(hours: 10)));
    expect(s.name, "Őszi szünet");
    expect(s.first, d(0));
    expect(s.last, d(4));
    expect(s.daysLeft, 4);
    expect(s.progress, closeTo(1 / 5, 1e-9));
    expect(s.nextLesson, isNull);
  });

  test('single break day has no progress', () {
    final days = [
      [_lesson(d(0).add(const Duration(hours: 8)), d(0).add(const Duration(hours: 9)))],
      [_breakDay(d(1), name: "Pályaorientációs nap")],
    ];
    final s = breakSpanFor(days, 1, d(1));
    expect(s.first, s.last);
    expect(s.progress, 0);
  });

  test('next lesson after the break', () {
    final thu = _lesson(d(3).add(const Duration(hours: 8)), d(3).add(const Duration(hours: 8, minutes: 45)));
    final days = [
      [_breakDay(d(0))],
      [_breakDay(d(1))],
      [_breakDay(d(2))],
      [thu],
    ];
    final s = breakSpanFor(days, 0, d(0));
    expect(s.last, d(2));
    expect(s.nextLesson, same(thu));
  });

  test('gapMinutes', () {
    final a = _lesson(DateTime(2026, 11, 3, 8), DateTime(2026, 11, 3, 8, 45));
    final b = _lesson(DateTime(2026, 11, 3, 8, 55), DateTime(2026, 11, 3, 9, 40));
    expect(gapMinutes(a, b), 10);
    expect(gapMinutes(_breakDay(d(0)), b), isNull);
    expect(gapMinutes(b, a), isNull);
  });

  test('lessonProgress and minutesLeft', () {
    final l = _lesson(DateTime(2026, 11, 3, 8), DateTime(2026, 11, 3, 8, 45));
    final now = DateTime(2026, 11, 3, 8, 20);
    expect(lessonProgress(l, now), closeTo(20 / 45, 1e-9));
    expect(minutesLeft(l, now), 25);
    expect(lessonProgress(l, DateTime(2026, 11, 3, 9)), isNull);
    expect(lessonProgress(_breakDay(d(0)), d(0)), isNull);
  });
}
