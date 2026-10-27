import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/justification.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';

final _caseType = KretaType.fromJson(
    {"azonosito": 1, "kod": "TMGI", "nev": "Tanulói mulasztás igazolása"});
final _justType =
    KretaType.fromJson({"azonosito": 2, "kod": "ORVOSI", "nev": "Orvosi igazolás"});
final _child = ChildData.fromJson({
  "vezetekNev": "Kamu",
  "keresztNev": "Diák",
  "oktatasiAzonosito": 72000000000,
  "osztaly": "9.A",
});

void main() {
  group('buildTmgiBody', () {
    final body = buildTmgiBody(
      child: _child,
      caseType: _caseType,
      justificationType: _justType,
      start: DateTime(2026, 10, 5, 23, 59),
      end: DateTime(2026, 10, 7),
      reason: "Beteg volt",
    );

    test('has exactly the official app keys', () {
      expect(body.keys.toSet(), {
        "tanuloCsaladiNev",
        "tanuloKeresztNev",
        "tanuloOktatasiAzonosito",
        "tanuloOsztaly",
        "tipus",
        "igazolasTipus",
        "tipusKod",
        "igazoltTavolletKezdeteDatum",
        "igazoltTavolletVegeDatum",
        "indoklas",
        "kerelemKotelezoDokumentumLista",
        "csatolmanyok",
      });
    });

    test('values match the official app', () {
      expect(body["tipusKod"], "TMGI");
      expect(body["igazoltTavolletKezdeteDatum"], "2026-10-05");
      expect(body["igazoltTavolletVegeDatum"], "2026-10-07");
      expect(body["tipus"], _caseType.json);
      expect(body["igazolasTipus"], _justType.json);
      expect(body["tanuloCsaladiNev"], "Kamu");
      expect(body["tanuloKeresztNev"], "Diák");
      expect(body["tanuloOktatasiAzonosito"], "72000000000");
      expect(body["tanuloOsztaly"], "9.A");
      expect(body["indoklas"], "Beteg volt");
      expect(body["kerelemKotelezoDokumentumLista"], isEmpty);
      expect(body["csatolmanyok"], isEmpty);
    });

    test('missing education id stays null', () {
      final child = ChildData.fromJson({"vezetekNev": "A", "keresztNev": "B"});
      expect(child.educationId, isNull);
      final b = buildTmgiBody(
          child: child,
          caseType: _caseType,
          justificationType: _justType,
          start: DateTime(2026, 10, 5),
          end: DateTime(2026, 10, 5));
      expect(b.containsKey("tanuloOktatasiAzonosito"), isTrue);
      expect(b["tanuloOktatasiAzonosito"], isNull);
    });
  });

  test('formatKretaDate pads', () {
    expect(formatKretaDate(DateTime(2026, 1, 2)), "2026-01-02");
  });

  test('isValidRange', () {
    expect(isValidRange(DateTime(2026, 10, 6), DateTime(2026, 10, 5)), isFalse);
    expect(isValidRange(DateTime(2026, 10, 5, 18), DateTime(2026, 10, 5, 8)),
        isTrue);
    expect(isValidRange(null, DateTime(2026, 10, 5)), isFalse);
    expect(isValidRange(DateTime(2026, 10, 5), null), isFalse);
  });

  test('JustificationCase tolerates a minimal item', () {
    final c = JustificationCase.fromJson({"azonosito": 1});
    expect(c.id, "1");
    expect(c.typeName, "–");
    expect(c.stateName, "–");
    expect(c.start, isNull);
  });

  test('JustificationCase reads a full item', () {
    final c = JustificationCase.fromJson({
      "azonosito": "7",
      "igazoltTavolletKezdeteDatum": "2026-10-05",
      "igazoltTavolletVegeDatum": "2026-10-07",
      "igazolasTipus": {"nev": "Orvosi igazolás"},
      "statusz": {"kod": "BEKULDVE", "nev": "Beküldve"},
      "bekuldesDatum": "2026-10-27T14:00:00Z",
      "indoklas": "x",
    });
    expect(c.start, DateTime(2026, 10, 5));
    expect(c.typeName, "Orvosi igazolás");
    expect(c.stateName, "Beküldve");
    expect(c.sent, isNotNull);
  });

  group('CaseProvider helpers', () {
    test('findTmgiType', () {
      final types = [
        KretaType.fromJson({"kod": "EGYEB", "nev": "x"}),
        KretaType.fromJson({"kod": "TMGI", "nev": "y"}),
      ];
      expect(findTmgiType(types)?.name, "y");
      expect(findTmgiType([types.first]), isNull);
    });

    test('parseSubmitError', () {
      expect(parseSubmitError(200, '{"azonosito": 1}'), isNull);
      expect(parseSubmitError(200, ''), isNull);
      expect(parseSubmitError(204, null), isNull);
      expect(parseSubmitError(200, '{"hibakod": "X", "uzenet": "Rossz dátum"}'),
          "Rossz dátum");
      expect(parseSubmitError(400, '{"Message": "Hibás kérés"}'), "Hibás kérés");
      expect(parseSubmitError(500, '<html>'),
          "A KRÉTA hibát adott vissza (500).");
      expect(parseSubmitError(null, null), "Nem sikerült elérni a KRÉTA-t.");
    });
  });
}
