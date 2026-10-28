import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/school_calendar.dart';

Map _entry(DateTime d, String type,
        {String desc = "", String? follows, String week = "MindegyikHet"}) =>
    {
      "Uid": "U${d.toIso8601String()}",
      // KRÉTA sends local midnight as UTC
      "Datum": d.toUtc().toIso8601String(),
      "Naptipus": {"Uid": "1", "Nev": type, "Leiras": desc},
      "ElteroOrarendSzerintiTanitasiNap":
          follows == null ? null : {"Uid": "2", "Nev": follows, "Leiras": ""},
      "OrarendiNapHetirendje": {"Uid": "3", "Nev": week, "Leiras": ""},
      "OsztalyCsoport": null,
    };

List<SchoolCalendarDay> _days(List<Map> json) =>
    SchoolCalendarDay.listFromJson(json);

void main() {
  test('parses the local date and drops "na" follow-day', () {
    final d = SchoolCalendarDay.fromJson(
        _entry(DateTime(2026, 10, 23), "oszi_szunet", follows: "na"));
    expect(d.date, DateTime(2026, 10, 23));
    expect(d.followsDay, isNull);
  });

  test('ordinary weekdays and weekends are skipped', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 10, 20), "tanitasi_nap"),
      _entry(DateTime(2026, 10, 24), "Pihenonap"),
    ]));
    expect(items, isEmpty);
  });

  test('a break over a weekend becomes one range, named by KRÉTA', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 10, 22), "tanitasi_nap"),
      _entry(DateTime(2026, 10, 23), "oszi_szunet", desc: "Őszi szünet"),
      _entry(DateTime(2026, 10, 24), "Pihenonap"),
      _entry(DateTime(2026, 10, 25), "Pihenonap"),
      _entry(DateTime(2026, 10, 26), "oszi_szunet", desc: "Őszi szünet"),
      _entry(DateTime(2026, 10, 27), "oszi_szunet", desc: "Őszi szünet"),
      _entry(DateTime(2026, 11, 2), "tanitasi_nap"),
    ]));
    expect(items.length, 1);
    expect(items.single.title, "Őszi szünet");
    expect(items.single.first, DateTime(2026, 10, 23));
    expect(items.single.last, DateTime(2026, 10, 27));
    expect(items.single.isFree, isTrue);
  });

  test('a school day between two free days splits them', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 11, 3), "tanitas_nelkuli_munkanap"),
      _entry(DateTime(2026, 11, 4), "tanitasi_nap"),
      _entry(DateTime(2026, 11, 5), "tanitas_nelkuli_munkanap"),
    ]));
    expect(items.length, 2);
    expect(items.first.title, "Tanítás nélküli munkanap");
  });

  test('Saturday working day says whose timetable it follows', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 12, 12), "tanitasi_nap", follows: "Hetfo"),
    ]));
    expect(items.single.title, "Tanítási nap");
    expect(items.single.note, "hétfői órarend szerint");
    expect(items.single.isFree, isFalse);
  });

  test('next free item: ongoing first, then upcoming, none after the year', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 10, 23), "oszi_szunet"),
      _entry(DateTime(2026, 10, 26), "oszi_szunet"),
      _entry(DateTime(2027, 1, 22), "elso_felev_vege"),
      _entry(DateTime(2026, 12, 21), "teli_szunet"),
    ]));
    expect(nextFreeItem(items, DateTime(2026, 10, 26, 9))!.type, "oszi_szunet");
    expect(nextFreeItem(items, DateTime(2026, 10, 27))!.type, "teli_szunet");
    expect(nextFreeItem(items, DateTime(2027, 1, 1)), isNull);
  });

  test('week label: A/B shown, "every week" hidden', () {
    SchoolWeek w(String type, String desc) => SchoolWeek.fromJson({
          "Uid": "W",
          "KezdoNapDatuma": DateTime(2026, 10, 26).toUtc().toIso8601String(),
          "VegNapDatuma": DateTime(2026, 11, 1).toUtc().toIso8601String(),
          "HetSorszama": 9,
          "Tipus": {"Uid": "1", "Nev": type, "Leiras": desc},
        });
    expect(w("MindegyikHet", "Minden héten").label, isNull);
    expect(w("A_het", "A hét").shortLabel, "A");
    expect(w("Paratlan", "Páratlan hét").shortLabel, "Páratlan hét");
    expect(w("A_het", "A hét").start, DateTime(2026, 10, 26));
    expect(w("A_het", "A hét").number, 9);
  });

  test('cache round trip keeps everything', () {
    final d = SchoolCalendarDay.fromJson(_entry(
        DateTime(2026, 12, 12), "tanitasi_nap",
        follows: "Hetfo", desc: "Tanítási nap"));
    final back = SchoolCalendarDay.fromJson(d.toCacheJson());
    expect(back.date, d.date);
    expect(back.followsDay, "Hetfo");
    expect(back.typeDesc, "Tanítási nap");
  });

  test('a break ending on Friday includes the weekend after it', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 10, 29), "oszi_szunet", desc: "Őszi szünet"),
      _entry(DateTime(2026, 10, 30), "oszi_szunet", desc: "Őszi szünet"),
      _entry(DateTime(2026, 11, 13), "tanitas_nelkuli_munkanap"),
    ]));
    expect(items.first.last, DateTime(2026, 11, 1));
    expect(items.first.length, 4);
    // a single day off is not stretched into a "3-day" item
    expect(items.last.isRange, isFalse);
  });

  test('a working Saturday right after a break is not swallowed', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 10, 30), "oszi_szunet", desc: "Őszi szünet"),
      _entry(DateTime(2026, 10, 31), "tanitasi_nap", follows: "Pentek"),
    ]));
    expect(items.first.last, DateTime(2026, 10, 30));
    expect(items.last.note, "pénteki órarend szerint");
  });

  test('real KRÉTA shape: names cleaned, own weekday not a note, merged', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 10, 28), "oszi_szunet",
          desc: "Őszi szünet (Nem órarendi nap) (Szerda)", follows: "Szerda"),
      _entry(DateTime(2026, 10, 29), "oszi_szunet",
          desc: "Őszi szünet (Nem órarendi nap) (Csütörtök)",
          follows: "Csutortok"),
      _entry(DateTime(2026, 10, 30), "oszi_szunet",
          desc: "Őszi szünet (Nem órarendi nap) (Péntek)", follows: "Pentek"),
      _entry(DateTime(2026, 10, 31), "Pihenonap", follows: "Szombat"),
      _entry(DateTime(2026, 11, 1), "munkaszuneti_nap",
          desc: "Munkaszüneti nap (Nem órarendi nap) (Vasárnap)",
          follows: "Vasarnap"),
    ]));
    expect(items.first.title, "Őszi szünet");
    expect(items.first.note, isNull);
    expect(items.first.first, DateTime(2026, 10, 28));
    expect(items.first.last, DateTime(2026, 11, 1));
    // the Sunday holiday right after the break is part of it
    expect(items.length, 1);
  });

  test('Christmas days inside the winter break do not split it', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2026, 12, 21), "teli_szunet", desc: "Téli szünet"),
      _entry(DateTime(2026, 12, 22), "teli_szunet", desc: "Téli szünet"),
      _entry(DateTime(2026, 12, 23), "teli_szunet", desc: "Téli szünet"),
      _entry(DateTime(2026, 12, 24), "teli_szunet", desc: "Téli szünet"),
      _entry(DateTime(2026, 12, 25), "munkaszuneti_nap", desc: "Munkaszüneti nap"),
      _entry(DateTime(2026, 12, 26), "munkaszuneti_nap", desc: "Munkaszüneti nap"),
      _entry(DateTime(2026, 12, 28), "teli_szunet", desc: "Téli szünet"),
      _entry(DateTime(2026, 12, 29), "teli_szunet", desc: "Téli szünet"),
      _entry(DateTime(2026, 12, 30), "teli_szunet", desc: "Téli szünet"),
      _entry(DateTime(2026, 12, 31), "teli_szunet", desc: "Téli szünet"),
      _entry(DateTime(2027, 1, 22), "elso_felev_vege"),
    ]));
    expect(items.length, 2);
    expect(items.first.title, "Téli szünet");
    expect(items.first.first, DateTime(2026, 12, 21));
    expect(items.first.last, DateTime(2026, 12, 31));
  });

  test('a lone holiday away from breaks stays its own row', () {
    final items = buildSchoolCalendar(_days([
      _entry(DateTime(2027, 3, 15), "munkaszuneti_nap", desc: "Munkaszüneti nap"),
      _entry(DateTime(2027, 4, 1), "tavaszi_szunet", desc: "Tavaszi szünet"),
    ]));
    expect(items.length, 2);
  });
}
