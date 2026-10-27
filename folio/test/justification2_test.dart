import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/justification.dart';

final _caseType =
    KretaType.fromJson({"azonosito": 1, "kod": "TMGI", "nev": "T"});
final _orvosi = KretaType.fromJson({
  "azonosito": "5",
  "kod": "ORVOSI",
  "nev": "Orvosi igazolás",
  "leiras": "Orvosi",
  "rovidNev": "Orvosi r"
});
final _gondv = KretaType.fromJson(
    {"azonosito": "6", "kod": "GONDVISELOI", "nev": "Gondviselői"});
final _child = ChildData.fromJson({"vezetekNev": "A", "keresztNev": "B"});
final _f1 = UploadedFile(name: "papir.pdf", tempId: "tmp-1");
final _f2 = UploadedFile(name: "busz.jpg", tempId: "tmp-2");

Map<String, dynamic> _body(KretaType t,
        {UploadedFile? mandatory, List<UploadedFile> others = const []}) =>
    buildTmgiBody(
        child: _child,
        caseType: _caseType,
        justificationType: t,
        start: DateTime(2026, 10, 5),
        end: DateTime(2026, 10, 5),
        mandatory: mandatory,
        others: others);

void main() {
  test('mandatoryDocTypeId', () {
    expect(mandatoryDocTypeId("ORVOSI"), 36);
    expect(mandatoryDocTypeId("HIVATALOS_TAVOLLET"), 39);
    expect(mandatoryDocTypeId("SZOLGALTATOI"), 40);
    expect(mandatoryDocTypeId("KIKERO"), 41);
    expect(mandatoryDocTypeId("GONDVISELOI"), isNull);
  });

  test('parseTempFile', () {
    expect(parseTempFile({"fajlAzonosito": "x"}, "a.pdf")?.tempId, "x");
    expect(parseTempFile({"fajlId": "y"}, "a.pdf")?.tempId, "y");
    expect(parseTempFile({"utvonal": "z"}, "a.pdf"), isNull);
    expect(parseTempFile(null, "a.pdf"), isNull);
  });

  test('mandatory document body shape', () {
    final b = _body(_orvosi, mandatory: _f1, others: [_f2]);
    expect(b["kerelemKotelezoDokumentumLista"], [
      {
        "fajlNev": "papir.pdf",
        "fajl": {"ideiglenesFajlAzonosito": "tmp-1"},
        "tipus": {
          "azonosito": "36",
          "rovidNev": "Orvosi r",
          "nev": "Orvosi igazolás",
          "leiras": "Orvosi",
        },
      }
    ]);
    expect(b["csatolmanyok"], [
      {
        "fajlNev": "busz.jpg",
        "fajl": {"ideiglenesFajlAzonosito": "tmp-2"}
      }
    ]);
  });

  test('mandatory file is dropped for a type without mandatory document', () {
    final b = _body(_gondv, mandatory: _f1, others: [_f2]);
    expect(b["kerelemKotelezoDokumentumLista"], isEmpty);
    expect((b["csatolmanyok"] as List).length, 1);
  });

  test('canSubmit', () {
    bool c(
            {bool range = true,
            KretaType? type,
            bool has = false,
            bool up = false}) =>
        canSubmit(rangeOk: range, type: type, hasMandatory: has, uploading: up);
    expect(c(type: _gondv), isTrue);
    expect(c(type: _orvosi), isFalse);
    expect(c(type: _orvosi, has: true), isTrue);
    expect(c(type: _gondv, up: true), isFalse);
    expect(c(type: null), isFalse);
    expect(c(type: _gondv, range: false), isFalse);
    expect(
        canSubmit(
            rangeOk: true,
            type: _gondv,
            hasMandatory: false,
            uploading: false,
            hasFailed: true),
        isFalse);
  });

  test('attachment size cap', () {
    expect(attachmentTooLarge(10 * 1024 * 1024), isFalse);
    expect(attachmentTooLarge(10 * 1024 * 1024 + 1), isTrue);
  });

  test('non-string codes do not crash parsing', () {
    final odd = {
      "azonosito": 1,
      "statusz": {"kod": 5, "nev": "x"},
      "hatarozatLista": [
        {"dontes": {"kod": 7}}
      ]
    };
    expect(JustificationCase.fromJson(odd).stateCode, isNull);
    final d = CaseDetail.fromJson(odd);
    expect(d.stateCode, isNull);
    expect(d.decisions.single.code, isNull);
  });

  test('KretaType equality by code and id', () {
    expect(
        KretaType.fromJson({"azonosito": "6", "kod": "GONDVISELOI"}), _gondv);
    expect(_gondv == _orvosi, isFalse);
  });

  test('stateLabel', () {
    expect(stateLabel("UJ", null), "Feldolgozásra vár");
    expect(stateLabel("HIANYPOTLAS_UZENETTEL", null), "Hiánypótlás szükséges");
    expect(stateLabel("ELFOGADVA", null), "Elfogadva");
    expect(stateLabel("ELUTASITVA", null), "Elutasítva");
    expect(stateLabel("VALAMI", "KRÉTA szöveg"), "KRÉTA szöveg");
    expect(stateLabel(null, null), "–");
  });

  group('CaseDetail', () {
    test('tolerates an empty map', () {
      final d = CaseDetail.fromJson({});
      expect(d.decisions, isEmpty);
      expect(d.needsRectification, isFalse);
      expect(d.handlerName, "–");
    });

    final full = {
      "azonosito": "9",
      "tipus": {"kod": "TMGI"},
      "tipusKod": "TMGI",
      "statusz": {"kod": "HIANYPOTLAS", "nev": "Hiánypótlás"},
      "ugyintezo": {"nev": "Kamu Ügyintéző"},
      "tanuloCsaladiNev": "A",
      "tanuloKeresztNev": "B",
      "tanuloOktatasiAzonosito": "7",
      "igazolasTipus": {"nev": "Orvosi igazolás"},
      "iktatottKerelem": {"azonosito": "k1"},
      "kerelemKotelezoDokumentumLista": [
        {"fajlNev": "papir.pdf", "azonosito": "d1"}
      ],
      "csatolmanyok": [
        {"fajlNev": "busz.jpg", "azonosito": "d2"}
      ],
      "hatarozatLista": [
        {
          "dontes": {
            "kod": "HIANYPOTLAS_UZENETTEL",
            "nev": "Hiánypótlás üzenettel"
          },
          "hatarozatDatum": "2026-10-20T10:00:00Z",
          "dontesSzovege": "Kérjük a papírt.",
          "alairoKretaAzonosito": 55,
          "iktatottHatarozat": {"azonosito": "h1"}
        }
      ]
    };

    test('reads a full case', () {
      final d = CaseDetail.fromJson(full);
      expect(d.studentName, "A B");
      expect(d.handlerName, "Kamu Ügyintéző");
      expect(d.filedId, "k1");
      expect(d.mandatoryDocs.single.name, "papir.pdf");
      expect(d.otherDocs.single.name, "busz.jpg");
      expect(d.decisions.single.label, "Hiánypótlás üzenettel");
      expect(d.decisions.single.signerId, 55);
      expect(d.decisions.single.filedId, "h1");
      expect(d.needsRectification, isTrue);
    });

    test('rectification already sent: state wins over the old decision', () {
      final sent = Map.of(full)
        ..["statusz"] = {"kod": "FOLYAMATBAN", "nev": "Hiánypótlás beküldve"};
      expect(CaseDetail.fromJson(sent).needsRectification, isFalse);
      final noState = Map.of(full)..remove("statusz");
      expect(CaseDetail.fromJson(noState).needsRectification, isTrue);
    });

    test('rectification body + guard', () {
      final d = CaseDetail.fromJson(full);
      final b = buildRectificationBody(d, [_f2]);
      expect(b["azonosito"], "9");
      expect(b["tipusKod"], "TMGI");
      expect(b["tipus"], {"kod": "TMGI"});
      expect(b["statusz"], {"kod": "HIANYPOTLAS", "nev": "Hiánypótlás"});
      expect(b["csatolmanyok"], [
        {
          "fajlNev": "busz.jpg",
          "fajl": {"ideiglenesFajlAzonosito": "tmp-2"}
        }
      ]);
      expect(canSubmitRectification([], false), isFalse);
      expect(canSubmitRectification([_f2], true), isFalse);
      expect(canSubmitRectification([_f2], false), isTrue);
      expect(canSubmitRectification([_f2], false, hasFailed: true), isFalse);
    });
  });
}
