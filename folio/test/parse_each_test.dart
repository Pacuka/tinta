import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/models/parse_each.dart';

void main() {
  Map grade(String uid, {Object? value = 5}) => {
        "Uid": uid,
        "SzamErtek": value,
        "SzovegesErtek": "Jeles(5)",
        "Tantargy": {"Uid": "1", "Nev": "matematika"},
      };

  test('one broken grade is skipped, the rest is kept', () {
    final grades = parseEach(
        [grade("1"), grade("2", value: "öt"), grade("3")], Grade.fromJson,
        what: "grade");
    expect(grades.map((g) => g.id), ["1", "3"]);
  });

  test('a non-map item is skipped too', () {
    final grades =
        parseEach([grade("1"), "kamu", null], Grade.fromJson, what: "grade");
    expect(grades.map((g) => g.id), ["1"]);
  });

  test('every item broken: throws, so the stored grades stay', () {
    expect(
        () => parseEach([grade("1", value: "öt"), "kamu"], Grade.fromJson,
            what: "grade"),
        throwsFormatException);
  });

  test('empty list is just empty', () {
    expect(parseEach([], Grade.fromJson, what: "grade"), isEmpty);
  });
}
