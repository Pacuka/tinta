import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/providers/school_calendar_provider.dart';

class _Fake implements SchoolCalendarBackend {
  @override
  String? userId = "u1";
  @override
  bool isDemo = false;
  List? calendarJson = [];
  List? weeksJson = [];
  int weekCalls = 0;
  final Map<String, Map> cache = {};

  @override
  Future<List?> calendar() async => calendarJson;
  @override
  Future<List?> weeks(DateTime from, DateTime to) async {
    weekCalls++;
    return weeksJson;
  }

  @override
  Future<Map?> readCache(String userId) async => cache[userId];
  @override
  Future<void> writeCache(String userId, Map json) async => cache[userId] = json;
}

Map _day(DateTime d, String type) => {
      "Datum": d.toUtc().toIso8601String(),
      "Naptipus": {"Nev": type, "Leiras": ""},
      "OrarendiNapHetirendje": {"Nev": "MindegyikHet", "Leiras": ""},
    };

Map _week(DateTime start, int n, String desc) => {
      "KezdoNapDatuma": start.toUtc().toIso8601String(),
      "VegNapDatuma": start.add(const Duration(days: 6)).toUtc().toIso8601String(),
      "HetSorszama": n,
      "Tipus": {"Nev": desc.isEmpty ? "MindegyikHet" : "X", "Leiras": desc},
    };

void main() {
  final now = DateTime(2026, 10, 28, 10);

  test('fetch loads the year and the current week, and caches them', () async {
    final b = _Fake()
      ..calendarJson = [_day(DateTime(2026, 10, 23), "oszi_szunet")]
      ..weeksJson = [_week(DateTime(2026, 10, 26), 9, "A hét")];
    final p = SchoolCalendarProvider.withBackend(b);
    await p.fetch(now: now);
    expect(p.items.single.type, "oszi_szunet");
    expect(p.weekOf(now)!.shortLabel, "A");
    expect(p.weekOf(DateTime(2026, 11, 3)), isNull);

    final again = SchoolCalendarProvider.withBackend(b);
    await again.restore();
    expect(again.days.length, 1);
    expect(again.weekOf(now)!.number, 9);
  });

  test('a failed fetch keeps the old list and reports an error', () async {
    final b = _Fake()..calendarJson = [_day(DateTime(2026, 10, 23), "oszi_szunet")];
    final p = SchoolCalendarProvider.withBackend(b);
    await p.fetch(now: now);
    b.calendarJson = null;
    await p.fetch(now: now);
    expect(p.days.length, 1);
    expect(p.error, isNotNull);
  });

  test('another account never sees the previous one', () async {
    final b = _Fake()
      ..calendarJson = [_day(DateTime(2026, 10, 23), "oszi_szunet")]
      ..weeksJson = [_week(DateTime(2026, 10, 26), 9, "A hét")];
    final p = SchoolCalendarProvider.withBackend(b);
    await p.fetch(now: now);
    b.userId = "u2";
    expect(p.days, isEmpty);
    expect(p.weekOf(now), isNull);
  });

  test('each week is asked only once unless forced', () async {
    final b = _Fake();
    final p = SchoolCalendarProvider.withBackend(b);
    await p.fetchWeek(now);
    await p.fetchWeek(now.add(const Duration(days: 1)));
    expect(b.weekCalls, 1);
    await p.fetchWeek(now, force: true);
    expect(b.weekCalls, 2);
  });

  test('demo accounts never call KRÉTA', () async {
    final b = _Fake()..isDemo = true;
    final p = SchoolCalendarProvider.withBackend(b);
    await p.fetch(now: now);
    expect(b.weekCalls, 0);
    expect(p.days, isEmpty);
  });
}
