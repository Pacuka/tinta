import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/controllers/timetable_controller.dart';
import 'package:folio_kreta_api/models/lesson.dart';

String _iso(DateTime d) => d.toIso8601String();
final _day = DateTime(2026, 11, 11);

Lesson _lesson(int index, int hour, {String subject = "Matematika"}) {
  final start = DateTime(2026, 11, 11, hour);
  return Lesson.fromJson({
    "Uid": "L$index",
    "Datum": _iso(_day),
    "KezdetIdopont": _iso(start),
    "VegIdopont": _iso(start.add(const Duration(minutes: 45))),
    "Oraszam": index,
    "Tantargy": {"Uid": "S-$subject", "Nev": subject},
  });
}

/// KRÉTA's special-day entry: no subject, midnight time, a name.
Lesson _special({int? index}) => Lesson.fromJson({
      "Uid": "SP",
      "Datum": _iso(_day),
      "KezdetIdopont": _iso(_day),
      "VegIdopont": _iso(_day),
      "Nev": "Pályaorientációs nap",
      if (index != null) "Oraszam": index,
    });

void main() {
  test('a gap between lessons is filled with one empty slot', () {
    final days = buildTimetableDays([_lesson(1, 8), _lesson(3, 10)]);
    expect(days.single.map((l) => l.lessonIndex), ['1', '2', '3']);
    expect(days.single[1].isEmpty, isTrue);
  });

  test('special-day entry is shown once, on top, without fake lessons', () {
    final days = buildTimetableDays([_special(), _lesson(2, 9), _lesson(3, 10)]);
    expect(days.single.map((l) => l.name).first, 'Pályaorientációs nap');
    expect(days.single.length, 3);
    expect(days.single.where((l) => l.isEmpty), isEmpty);
  });

  test('special-day entry with a lesson number does not create slots', () {
    final days =
        buildTimetableDays([_special(index: 0), _lesson(2, 9), _lesson(3, 10)]);
    expect(days.single.where((l) => l.subject.id == '').length, 1);
    expect(days.single.where((l) => l.isEmpty), isEmpty);
    expect(days.single.length, 3);
  });

  test('a real 0th lesson stays', () {
    final days = buildTimetableDays([_lesson(0, 7), _lesson(1, 8)]);
    expect(days.single.map((l) => l.lessonIndex), ['0', '1']);
  });
}
