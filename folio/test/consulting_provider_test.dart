import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:folio_kreta_api/providers/consulting_provider.dart';

void main() {
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
