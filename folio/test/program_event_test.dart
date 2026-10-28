import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/program_event.dart';

final _start = DateTime(2026, 11, 20, 10);

Map _lep({Object? uid = "123", bool? ok}) => {
      "Uid": uid,
      "EloadasNev": " Diótörő ",
      "EloadasKezdete": _start.toUtc().toIso8601String(),
      "EloadasVege": _start.add(const Duration(hours: 2)).toUtc().toIso8601String(),
      "Datum": DateTime(2026, 11, 1).toUtc().toIso8601String(),
      "SzervezetNev": "Opera",
      "Helyszin": "Budapest",
      "Megjelent": false,
      "GondviseloElfogadas": ok,
    };

void main() {
  test('LÉP parses, numeric Uid becomes the id sent back', () {
    final e = ProgramEvent.fromJson(ProgramKind.lep, _lep(ok: null))!;
    expect(e.id, 123);
    expect(e.title, "Diótörő");
    expect(e.start, _start);
    expect(e.permitted, isNull);
    expect(e.decisionBody(true), {"EloadasId": 123, "Dontes": true});
  });

  test('NÉP uses Id and its own field names', () {
    final e = ProgramEvent.fromJson(ProgramKind.nep, {
      "Id": 7,
      "ProgramNev": "Élménytábor",
      "Kezdete": _start.toUtc().toIso8601String(),
      "Vege": _start.toUtc().toIso8601String(),
      "GondviseloElfogadas": false,
    })!;
    expect(e.permitted, isFalse);
    expect(e.decisionBody(false), {"Id": 7, "Dontes": false});
  });

  test('broken entries are skipped, not fatal', () {
    final list = ProgramEvent.listFromJson(
        ProgramKind.lep, [_lep(uid: "abc"), _lep(), "junk"]);
    expect(list.length, 1);
  });

  test('decision is possible until one day before the start', () {
    final e = ProgramEvent.fromJson(ProgramKind.lep, _lep())!;
    expect(e.canDecide(DateTime(2026, 11, 19, 9)), isTrue);
    expect(e.canDecide(DateTime(2026, 11, 19, 11)), isFalse);
  });

  test('cache round trip', () {
    final e = ProgramEvent.fromJson(ProgramKind.lep, _lep(ok: true))!;
    final back = ProgramEvent.fromCacheJson(e.toCacheJson())!;
    expect(back.id, 123);
    expect(back.kind, ProgramKind.lep);
    expect(back.permitted, isTrue);
    expect(back.place, "Budapest");
  });

  test('school modules and legal representative', () {
    final student = {
      "Intezmeny": {
        "Rendszermodulok": [
          {"Tipus": "LEP", "IsAktiv": true},
          {"Tipus": "NEP", "IsAktiv": false},
        ]
      },
      "Gondviselok": [
        {"Nev": "Kamu Apa", "IsTorvenyesKepviselo": true},
        {"Nev": "Kamu Nagymama", "IsTorvenyesKepviselo": false},
      ],
    };
    expect(schoolModuleActive(student, "LEP"), isTrue);
    expect(schoolModuleActive(student, "NEP"), isFalse);
    expect(schoolModuleActive(null, "LEP"), isFalse);
    expect(isLegalRepresentative(student, " kamu apa"), isTrue);
    expect(isLegalRepresentative(student, "Kamu Nagymama"), isFalse);
    expect(isLegalRepresentative(student, "Valaki Más"), isNull);
  });
}
