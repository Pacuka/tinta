import 'package:flutter_test/flutter_test.dart';
import 'package:folio/ui/filter/widgets/consulting.dart' as consulting_filter;
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_mobile_ui/pages/consulting/ics.dart';

ConsultingHour _hour({required DateTime start, bool mine = true}) =>
    ConsultingHour(
      id: "FO1",
      teacherId: "TA",
      teacherName: "Kamu Tanár Anna",
      start: start,
      end: start.add(const Duration(hours: 1)),
      signupEnabled: true,
      room: "12",
      slots: [
        ConsultingSlot(
            id: "FO1-1",
            start: start.add(const Duration(minutes: 10)),
            end: start.add(const Duration(minutes: 20)),
            mine: mine),
      ],
    );

void main() {
  test('ics event', () {
    final hour = _hour(start: DateTime.utc(2026, 11, 5, 15).toLocal());
    final ics = buildIcs(hour, hour.slots.first);
    final lines = ics.split("\r\n");
    expect(lines.first, "BEGIN:VCALENDAR");
    expect(lines, contains("VERSION:2.0"));
    expect(lines, contains("PRODID:-//Tinta//Fogadoora//HU"));
    expect(lines, contains("BEGIN:VEVENT"));
    expect(lines, contains("UID:FO1-1@tinta"));
    expect(lines, contains("DTSTART:20261105T151000Z"));
    expect(lines, contains("DTEND:20261105T152000Z"));
    expect(lines, contains("SUMMARY:Fogadóóra – Kamu Tanár Anna"));
    expect(lines, contains("LOCATION:12"));
    expect(lines, contains("END:VEVENT"));
    expect(lines.where((l) => l.isNotEmpty).last, "END:VCALENDAR");
    expect(ics.replaceAll("\r\n", ""), isNot(contains("\n")));
  });

  test('ics escapes commas and semicolons', () {
    final hour = _hour(start: DateTime(2026, 11, 5, 16));
    hour.room = "A; épület, 12";
    expect(buildIcs(hour, hour.slots.first),
        contains("LOCATION:A\\; épület\\, 12"));
  });

  test('home feed shows only own upcoming bookings', () {
    final future = DateTime.now().add(const Duration(days: 2));
    final past = DateTime.now().subtract(const Duration(days: 2));
    final items = consulting_filter.getWidgets([
      _hour(start: future),
      _hour(start: future, mine: false),
      _hour(start: past),
    ]);
    expect(items.length, 1);
    expect(items.first.date, future.add(const Duration(minutes: 10)));
  });

  test('a failing share reports false instead of throwing', () async {
    final hour = _hour(start: DateTime(2026, 11, 5, 16));
    final ok = await shareIcs(hour, hour.slots.first,
        writeAndShare: (_) async => throw Exception("no share target"));
    expect(ok, isFalse);
    expect(
        await shareIcs(hour, hour.slots.first, writeAndShare: (_) async {}),
        isTrue);
  });
}
