import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:folio_kreta_api/providers/consulting_provider.dart';

void main() {
  providerTests();

  group('parseConsultingError', () {
    test('slot taken by someone else', () {
      expect(
          parseConsultingError(400,
              '{"uzenet":"A választott időpont már foglalt.","hibakod":"FogadooraIdopontFoglalt"}'),
          consultingTakenMessage);
    });
    test('already booked one', () {
      expect(
          parseConsultingError(400,
              '{"uzenet":"Ön már foglalt egy időpontot!","hibakod":"FogadooraMarJelentkezett"}'),
          consultingAlreadyMessage);
    });
    test('RF5: no response is uncertain, not a plain failure', () {
      expect(parseConsultingError(null, null), uncertainSubmitMessage);
    });
    test('other server error', () {
      expect(parseConsultingError(500, ""), consultingFailedMessage);
      expect(parseConsultingError(400, "<html>"), consultingFailedMessage);
    });
    test('success', () {
      expect(parseConsultingError(200, ""), isNull);
      expect(parseConsultingError(204, null), isNull);
    });
  });

  test('exact texts', () {
    expect(consultingTakenMessage,
        "Ezt az időpontot közben elvitték, válassz másikat!");
    expect(consultingAlreadyMessage, "Már van foglalásod ennél a tanárnál.");
    expect(consultingFailedMessage, "Nem sikerült. Próbáld újra később!");
  });

  test('urls', () {
    final from = DateTime.utc(2026, 10, 26);
    final to = DateTime.utc(2027, 1, 25);
    expect(
        KretaAPI.consultingHours("kamu", from, to),
        endsWith(
            "/ellenorzo/V3/Sajat/Fogadoorak?datumTol=2026-10-26T00:00:00.000Z&datumIg=2027-01-25T00:00:00.000Z"));
    expect(KretaAPI.consultingHour("kamu", "FO1"),
        endsWith("/ellenorzo/V3/Sajat/Fogadoorak/FO1"));
    expect(KretaAPI.consultingReservation("kamu", "FO1-1"),
        endsWith("/ellenorzo/V3/Sajat/Fogadoorak/Idopontok/Jelentkezesek/FO1-1"));
  });

  test('range is yesterday .. +90 days', () {
    final (from, to) = consultingRange(DateTime(2026, 10, 27, 15));
    expect(from, DateTime(2026, 10, 26));
    expect(to, DateTime(2027, 1, 25));
  });
}

/// Scripted backend: each list() call returns the next queued future.
class FakeBackend implements ConsultingBackend {
  @override
  String? userId = "u1";
  final lists = <Completer<List?>>[];
  final posted = <String>[];
  int postStatus = 200;

  Completer<List?> queueList() {
    final c = Completer<List?>();
    lists.add(c);
    return c;
  }

  @override
  bool get isDemo => false;

  @override
  Future<List?> list(DateTime from, DateTime to) => lists.removeAt(0).future;

  @override
  Future<(int?, String?)> book(String slotId) async {
    posted.add(slotId);
    return (postStatus, "");
  }

  @override
  Future<int?> cancel(String slotId) async => 200;

  @override
  Future<List?> readCache(String userId) async => null;

  @override
  Future<void> writeCache(String userId, List json) async {}
}

List _list({required bool booked}) => [
      {
        "Tanar": {"Uid": "TA", "Nev": "Anna"},
        "Fogadoorak": [
          {
            "Uid": "FO1",
            "KezdoIdopont": "2099-11-05T15:00:00Z",
            "VegIdopont": "2099-11-05T16:00:00Z",
            "IsJelentkezesFeatureEnabled": true,
            "Terem": {"Nev": 12},
            "Idopontok": [
              {
                "Uid": "FO1-1",
                "KezdoIdopont": "2099-11-05T15:10:00Z",
                "VegIdopont": "2099-11-05T15:20:00Z",
                "IsJelentkeztem": booked,
              }
            ],
          }
        ],
      }
    ];

void providerTests() {
  test('I3: an older slow fetch does not overwrite the booking', () async {
    final b = FakeBackend();
    final p = ConsultingProvider.withBackend(b);
    final slow = b.queueList();
    final slowFetch = p.fetch();
    final afterBook = b.queueList();
    final hourStub = ConsultingHour.listFromJson(_list(booked: false)).single;
    final booking = p.book(hourStub.slots.single, hourStub);
    afterBook.complete(_list(booked: true));
    expect(await booking, isNull);
    expect(p.hours.single.myBooking?.id, "FO1-1");
    slow.complete(_list(booked: false));
    await slowFetch;
    expect(p.hours.single.myBooking?.id, "FO1-1");
    expect(p.loading, isFalse);
  });

  test('I1: after an account switch the old list is hidden and booking refused',
      () async {
    final b = FakeBackend();
    final p = ConsultingProvider.withBackend(b);
    b.queueList().complete(_list(booked: true));
    await p.fetch();
    expect(p.hours, isNotEmpty);
    b.userId = "u2";
    expect(p.hours, isEmpty);
    final hour = ConsultingHour.listFromJson(_list(booked: true)).single;
    expect(await p.cancel(hour.slots.single, hour), consultingFailedMessage);
    expect(await p.book(hour.slots.single, hour), consultingFailedMessage);
    expect(b.posted, isEmpty);
  });

  test('2xx with a non-JSON page is uncertain', () {
    expect(parseConsultingError(200, "<html>karbantartás</html>"),
        uncertainSubmitMessage);
  });

  test('non-string room does not throw', () {
    final hour = ConsultingHour.listFromJson(_list(booked: false)).single;
    expect(hour.room, "12");
  });
}
