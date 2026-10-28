import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/models/program_event.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:folio_kreta_api/providers/program_event_provider.dart';

class _Fake implements ProgramEventBackend {
  @override
  String? userId = "u1";
  @override
  bool isDemo = false;
  @override
  bool isParent = true;
  @override
  Map? student = {
    "Intezmeny": {
      "Rendszermodulok": [
        {"Tipus": "LEP", "IsAktiv": true},
        {"Tipus": "NEP", "IsAktiv": true},
      ]
    },
    "Gondviselok": [
      {"Nev": "Kamu Apa", "IsTorvenyesKepviselo": true}
    ],
  };
  @override
  String guardianName = "Kamu Apa";
  Map<ProgramKind, List?> lists = {ProgramKind.lep: [], ProgramKind.nep: []};
  (int?, String?) answer = (200, "");
  final sent = <Map>[];
  final Map<String, List> cache = {};

  @override
  Future<List?> list(ProgramKind kind) async => lists[kind];
  @override
  Future<(int?, String?)> decide(ProgramKind kind, Map<String, Object> body) async {
    sent.add(body);
    return answer;
  }

  @override
  Future<List?> readCache(String userId) async => cache[userId];
  @override
  Future<void> writeCache(String userId, List json) async => cache[userId] = json;
}

final _future = DateTime.now().add(const Duration(days: 10));

Map _lep(int id, DateTime start, {bool? ok}) => {
      "Uid": "$id",
      "EloadasNev": "Előadás $id",
      "EloadasKezdete": start.toUtc().toIso8601String(),
      "EloadasVege": start.toUtc().toIso8601String(),
      "GondviseloElfogadas": ok,
    };

void main() {
  test('fetch merges LÉP + NÉP, newest first, and counts pending', () async {
    final b = _Fake()
      ..lists = {
        ProgramKind.lep: [_lep(1, _future), _lep(2, DateTime(2026, 1, 1), ok: true)],
        ProgramKind.nep: [
          {"Id": 5, "ProgramNev": "Tábor",
           "Kezdete": _future.add(const Duration(days: 3)).toUtc().toIso8601String(),
           "Vege": _future.toUtc().toIso8601String()}
        ],
      };
    final p = ProgramEventProvider.withBackend(b);
    await p.fetch();
    expect(p.events.map((e) => e.id), [5, 1, 2]);
    expect(p.pendingCount(DateTime.now()), 2);
  });

  test('module off: nothing asked, menu hidden', () async {
    final b = _Fake()..student = {"Intezmeny": {"Rendszermodulok": []}};
    final p = ProgramEventProvider.withBackend(b);
    await p.fetch();
    expect(p.available, isFalse);
  });

  test('a decision is sent with the right body and shown at once', () async {
    final b = _Fake()..lists = {ProgramKind.lep: [_lep(1, _future)], ProgramKind.nep: []};
    final p = ProgramEventProvider.withBackend(b);
    await p.fetch();
    expect(await p.decide(p.events.single, true), isNull);
    expect(b.sent.single, {"EloadasId": 1, "Dontes": true});
    expect(p.events.single.permitted, isTrue);
  });

  test('not the legal representative / a student: blocked, nothing sent', () async {
    final b = _Fake()
      ..lists = {ProgramKind.lep: [_lep(1, _future)], ProgramKind.nep: []}
      ..guardianName = "Kamu Nagymama"
      ..student = {
        "Intezmeny": {"Rendszermodulok": [{"Tipus": "LEP", "IsAktiv": true}]},
        "Gondviselok": [{"Nev": "Kamu Nagymama", "IsTorvenyesKepviselo": false}],
      };
    final p = ProgramEventProvider.withBackend(b);
    await p.fetch();
    expect(await p.decide(p.events.single, true), programNotLegalRepMessage);
    b.isParent = false;
    b.guardianName = "";
    expect(await p.decide(p.events.single, true), programNotLegalRepMessage);
    expect(b.sent, isEmpty);
  });

  test('too late: blocked', () async {
    final soon = DateTime.now().add(const Duration(hours: 5));
    final b = _Fake()..lists = {ProgramKind.lep: [_lep(1, soon)], ProgramKind.nep: []};
    final p = ProgramEventProvider.withBackend(b);
    await p.fetch();
    expect(await p.decide(p.events.single, false), programTooLateMessage);
    expect(b.sent, isEmpty);
  });

  test('KRÉTA error text is shown; no answer = uncertain', () async {
    final b = _Fake()..lists = {ProgramKind.lep: [_lep(1, _future)], ProgramKind.nep: []};
    final p = ProgramEventProvider.withBackend(b);
    await p.fetch();
    b.answer = (400, '{"uzenet": "A határidő lejárt."}');
    expect(await p.decide(p.events.single, true), "A határidő lejárt.");
    expect(p.events.single.permitted, isNull);
    b.answer = (null, null);
    expect(await p.decide(p.events.single, true), uncertainSubmitMessage);
  });

  test('one list failing keeps the old items of that kind', () async {
    final b = _Fake()
      ..lists = {ProgramKind.lep: [_lep(1, _future)], ProgramKind.nep: []};
    final p = ProgramEventProvider.withBackend(b);
    await p.fetch();
    b.lists = {ProgramKind.lep: null, ProgramKind.nep: []};
    await p.fetch();
    expect(p.events.single.id, 1);
    expect(p.error, isNotNull);
  });

  test('account switch hides the other account', () async {
    final b = _Fake()..lists = {ProgramKind.lep: [_lep(1, _future)], ProgramKind.nep: []};
    final p = ProgramEventProvider.withBackend(b);
    await p.fetch();
    b.userId = "u2";
    expect(p.events, isEmpty);
  });
}
