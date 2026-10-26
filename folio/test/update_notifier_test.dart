import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/update_notifier.dart';
import 'package:folio_kreta_api/models/lesson.dart';

Lesson lesson({
  String id = "L1",
  String status = "Naplozott",
  String? substitute,
  String room = "32",
}) =>
    Lesson.fromJson({
      "Uid": id,
      "Datum": "2026-11-02T00:00:00Z",
      "KezdetIdopont": "2026-11-02T08:00:00Z",
      "VegIdopont": "2026-11-02T08:45:00Z",
      "Oraszam": 1,
      "Allapot": {"Uid": "1", "Nev": status, "Leiras": status},
      "Tantargy": {"Uid": "S1", "Nev": "Matematika"},
      "TeremNeve": room,
      if (substitute != null) "HelyettesTanarNeve": substitute,
    });

void main() {
  final file = File('${Directory.systemTemp.path}/tinta_notify_test.json');

  test('first run records silently', () {
    final s = NotifyState.empty(file, firstRun: true);
    expect(s.add("grades", "g1"), isTrue);
    expect(s.add("grades", "g1"), isFalse);
    expect(s.lessonChange(lesson(status: "Elmaradt")), isNull);
  });

  test('lesson on an unknown day is just recorded', () {
    final s = NotifyState.empty(file);
    expect(s.lessonChange(lesson()), isNull);
  });

  test('cancellation, substitute and room change are reported', () {
    final s = NotifyState.empty(file);
    s.lessonChange(lesson());
    expect(s.lessonChange(lesson(status: "Elmaradt")),
        "Elmarad: Matematika");

    final s2 = NotifyState.empty(file);
    s2.lessonChange(lesson());
    expect(s2.lessonChange(lesson(substitute: "Kiss Anna")),
        "Helyettesítés: Matematika – Kiss Anna");

    final s3 = NotifyState.empty(file);
    s3.lessonChange(lesson());
    expect(s3.lessonChange(lesson(room: "Torna")),
        "Teremcsere: Matematika – Torna");
  });

  test('unchanged lesson is not reported twice', () {
    final s = NotifyState.empty(file);
    s.lessonChange(lesson());
    s.lessonChange(lesson(status: "Elmaradt"));
    expect(s.lessonChange(lesson(status: "Elmaradt")), isNull);
  });

  test('new cancelled lesson on a known day is reported', () {
    final s = NotifyState.empty(file);
    s.lessonChange(lesson(id: "L1"));
    expect(s.lessonChange(lesson(id: "L2", status: "Elmaradt")),
        "Elmarad: Matematika");
  });
}
