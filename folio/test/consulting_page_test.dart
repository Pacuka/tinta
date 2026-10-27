import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_mobile_ui/pages/consulting/consulting_sheet.dart';
import 'package:intl/date_symbol_data_local.dart';

ConsultingHour _hour({
  bool signup = true,
  DateTime? deadline,
  bool mine = false,
  DateTime? start,
}) {
  final s = start ?? DateTime(2026, 11, 5, 16);
  return ConsultingHour(
    id: "FO1",
    teacherId: "TA",
    teacherName: "Kamu Tanár Anna",
    start: s,
    end: s.add(const Duration(hours: 1)),
    deadline: deadline ?? DateTime(2026, 11, 4, 23, 59),
    signupEnabled: signup,
    room: "12",
    slots: [
      ConsultingSlot(
          id: "FO1-0",
          start: s,
          end: s.add(const Duration(minutes: 10))),
      ConsultingSlot(
          id: "FO1-1",
          start: s.add(const Duration(minutes: 10)),
          end: s.add(const Duration(minutes: 20)),
          mine: mine),
    ],
  );
}

final _now = DateTime(2026, 11, 2, 10);

void main() {
  setUpAll(() => initializeDateFormatting("hu_HU"));

  group('consultingStateLabel', () {
    test('each state', () {
      expect(consultingStateLabel(_hour(), _now), "Szabad jelentkezés");
      expect(consultingStateLabel(_hour(mine: true), _now),
          "Jelentkezés leadva · 16:10");
      expect(consultingStateLabel(_hour(signup: false), _now),
          "Nem kell jelentkezni");
      expect(consultingStateLabel(_hour(), DateTime(2026, 11, 5, 0)),
          "Lezárult");
      expect(
          consultingStateLabel(
              _hour(deadline: DateTime(2026, 11, 5, 17)),
              DateTime(2026, 11, 5, 16, 30)),
          "Nincs szabad hely");
    });
  });

  group('deadlineHint', () {
    test('days left', () {
      expect(deadlineHint(_hour(), _now), "Még 2 napig jelentkezhetsz");
    });
    test('last day', () {
      expect(deadlineHint(_hour(), DateTime(2026, 11, 4, 9)),
          "Ma még jelentkezhetsz");
    });
    test('passed or not open', () {
      expect(deadlineHint(_hour(), DateTime(2026, 11, 5, 9)), isNull);
      expect(deadlineHint(_hour(mine: true), _now), isNull);
      expect(deadlineHint(_hour(signup: false), _now), isNull);
    });
  });

  testWidgets('RF2: double tap on book sends one request', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConsultingSheet(
          hour: _hour(start: DateTime.now().add(const Duration(days: 3))),
          onBook: (slot) async {
            calls++;
            await Future.delayed(const Duration(milliseconds: 300));
            return null;
          },
          onCancel: (slot) async => null,
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key("consulting-slot-FO1-1")));
    await tester.pump();
    await tester.tap(find.byKey(const Key("consulting-book")));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("consulting-confirm")));
    await tester.pump();
    // second tap while the first request is in flight
    await tester.tap(find.byKey(const Key("consulting-book")),
        warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    // no second confirmation dialog and exactly one request
    expect(find.byKey(const Key("consulting-confirm")), findsNothing);
    expect(calls, 1);
  });
}
