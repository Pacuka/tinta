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
}
