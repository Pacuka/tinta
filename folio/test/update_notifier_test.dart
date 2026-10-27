import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/update_notifier.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:intl/date_symbol_data_local.dart';

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

  group('consultingNotes', () {
    setUpAll(() => initializeDateFormatting("hu"));

    ConsultingHour hour({bool mine = false, DateTime? start}) {
      final s = start ?? DateTime(2026, 11, 5, 16);
      return ConsultingHour(
        id: "FO1",
        teacherId: "TA",
        teacherName: "Kamu Tanár Anna",
        start: s,
        end: s.add(const Duration(hours: 1)),
        signupEnabled: true,
        room: "12",
        slots: [
          ConsultingSlot(
              id: "FO1-1",
              start: s.add(const Duration(minutes: 10)),
              end: s.add(const Duration(minutes: 20)),
              mine: mine),
        ],
      );
    }

    test('new consultation hour once', () {
      final s = NotifyState.empty(file);
      final now = DateTime(2026, 11, 1, 10);
      final first = consultingNotes([hour()], s, now, enabled: true);
      expect(first.length, 1);
      expect(first.single.$1, "Új fogadóóra: Kamu Tanár Anna");
      expect(first.single.$2, contains("16:00–17:00"));
      expect(consultingNotes([hour()], s, now, enabled: true), isEmpty);
    });

    test('morning reminder on the day of a booking', () {
      final s = NotifyState.empty(file);
      final h = hour(mine: true);
      s.add("consulting", h.id); // already announced
      expect(consultingNotes([h], s, DateTime(2026, 11, 5, 6), enabled: true),
          isEmpty);
      final notes =
          consultingNotes([h], s, DateTime(2026, 11, 5, 7, 30), enabled: true);
      expect(notes.single.$1, "Ma fogadóóra: Kamu Tanár Anna");
      expect(notes.single.$2, "16:10 · 12");
      expect(
          consultingNotes([h], s, DateTime(2026, 11, 5, 8), enabled: true),
          isEmpty);
    });

    test('no reminder after the slot started, nothing when disabled', () {
      final s = NotifyState.empty(file);
      final h = hour(mine: true);
      expect(
          consultingNotes([h], s, DateTime(2026, 11, 5, 16, 15), enabled: true)
              .where((n) => n.$1.startsWith("Ma ")),
          isEmpty);
      final s2 = NotifyState.empty(file);
      expect(consultingNotes([h], s2, DateTime(2026, 11, 5, 8), enabled: false),
          isEmpty);
    });

    test('past hours are recorded silently', () {
      final s = NotifyState.empty(file);
      expect(
          consultingNotes([hour(start: DateTime(2026, 10, 1, 16))], s,
              DateTime(2026, 11, 1), enabled: true),
          isEmpty);
    });
  });
}
