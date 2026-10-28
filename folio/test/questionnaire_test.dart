import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/class_master.dart';
import 'package:folio_kreta_api/models/questionnaire.dart';

Map _round() => {
      "BekuldesKezdete": DateTime(2026, 10, 1).toUtc().toIso8601String(),
      "BekuldesVege": DateTime(2026, 11, 30).toUtc().toIso8601String(),
      "Kerdoivek": [
        {
          "TanarId": 42,
          "TanarNev": "Kiss Anna",
          "TanitottTantargyak": "Matematika",
          "Kerdoiv": {
            "Id": 9,
            "Kerdesek": [
              {"Id": 1, "Text": "Érthetően magyaráz?", "Tipus": "Grade"},
              {"Id": 2, "Text": "Mit tartasz meg?", "Tipus": "Text"},
            ]
          }
        },
        {"TanarId": 43, "Kerdoiv": {"Id": 9, "Kerdesek": []}},
        "junk",
      ],
    };

void main() {
  test('parses the round, drops broken or empty questionnaires', () {
    final r = QuestionnaireRound.fromJson(_round());
    expect(r.items.length, 1);
    final q = r.items.single;
    expect(q.questions.map((x) => x.type), [QuestionType.grade, QuestionType.text]);
    expect(r.isOpen(DateTime(2026, 10, 28)), isTrue);
    expect(r.isOpen(DateTime(2026, 12, 1)), isFalse);
    // cache round trip
    final back = QuestionnaireRound.fromJson(r.toJson());
    expect(back.items.single.teacherName, "Kiss Anna");
    expect(back.end, r.end);
  });

  test('complete only with 1-5 grades and non-empty text', () {
    final q = QuestionnaireRound.fromJson(_round()).items.single;
    expect(q.isComplete({1: "5"}), isFalse);
    expect(q.isComplete({1: "6", 2: "jó"}), isFalse);
    expect(q.isComplete({1: "4", 2: "   "}), isFalse);
    expect(q.isComplete({1: "4", 2: "x" * 1001}), isFalse);
    expect(q.isComplete({1: "4", 2: " jó "}), isTrue);
    expect(q.submitBody({1: "4", 2: " jó "}), {
      "TanarId": 42,
      "Valaszok": [
        {"KerdesId": 1, "Valasz": "4"},
        {"KerdesId": 2, "Valasz": "jó"},
      ],
    });
  });

  test('class master: contacts, uids from active groups', () {
    final m = ClassMaster.fromJson({
      "Uid": "77",
      "Tanar": {
        "Uid": "T1",
        "Alkalmazott": {
          "Nev": " Kiss Anna ",
          "Emailek": [{"Email": "kiss@iskola.hu"}, {"Email": "kiss@iskola.hu"}],
          "Telefonok": [{"Telefonszam": ""}],
        }
      }
    })!;
    expect(m.name, "Kiss Anna");
    expect(m.emails, ["kiss@iskola.hu"]);
    expect(m.phones, isEmpty);
    expect(ClassMaster.fromJson(m.toJson())!.emails, m.emails);
    expect(
        classMasterUids([
          {"OsztalyFonok": {"Uid": "77"}, "IsAktiv": true},
          {"OsztalyFonok": {"Uid": "78"}, "IsAktiv": false},
          {"OsztalyFonok": null},
          {"OsztalyFonok": {"Uid": "79"}},
        ]),
        "77;79");
  });
}
