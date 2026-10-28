import 'package:flutter_test/flutter_test.dart';
import 'package:folio_kreta_api/providers/questionnaire_provider.dart';

class _Fake implements SchoolInfoBackend {
  @override
  String? userId = "u1";
  @override
  bool isDemo = false;
  @override
  Map? student = {
    "Intezmeny": {
      "Rendszermodulok": [{"Tipus": "PedterKerdoiv", "IsAktiv": true}]
    }
  };
  Map? round;
  List? groupList = [
    {"OsztalyFonok": {"Uid": "77"}, "IsAktiv": true}
  ];
  String? askedUids;
  (int?, String?) answer = (200, "");
  final sent = <Map>[];
  final Map<String, Map> cache = {};

  @override
  Future<Map?> questionnaires() async => round;
  @override
  Future<(int?, String?)> submitQuestionnaire(Map<String, Object> body) async {
    sent.add(body);
    return answer;
  }

  @override
  Future<List?> groups() async => groupList;
  @override
  Future<List?> classMasters(String uids) async {
    askedUids = uids;
    return [
      {"Uid": "77", "Tanar": {"Alkalmazott": {"Nev": "Kiss Anna", "Emailek": [], "Telefonok": []}}}
    ];
  }

  @override
  Future<Map?> readCache(String userId) async => cache[userId];
  @override
  Future<void> writeCache(String userId, Map json) async => cache[userId] = json;
}

Map _round() => {
      "BekuldesKezdete": DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String(),
      "BekuldesVege": DateTime.now().add(const Duration(days: 10)).toUtc().toIso8601String(),
      "Kerdoivek": [
        for (final id in [1, 2])
          {
            "TanarId": id,
            "TanarNev": "Tanár $id",
            "Kerdoiv": {
              "Id": 9,
              "Kerdesek": [{"Id": 1, "Text": "?", "Tipus": "Grade"}]
            }
          }
      ],
    };

void main() {
  test('fetch: questionnaires + class master, cached', () async {
    final b = _Fake()..round = _round();
    final p = SchoolInfoProvider.withBackend(b);
    await p.fetch();
    expect(p.open(DateTime.now()).length, 2);
    expect(b.askedUids, "77");
    expect(p.classMasters.single.name, "Kiss Anna");
    final again = SchoolInfoProvider.withBackend(b);
    await again.restore();
    expect(again.round!.items.length, 2);
    expect(again.classMasters.single.name, "Kiss Anna");
  });

  test('module off: questionnaires not asked, class master still', () async {
    final b = _Fake()
      ..round = _round()
      ..student = {"Intezmeny": {"Rendszermodulok": []}};
    final p = SchoolInfoProvider.withBackend(b);
    await p.fetch();
    expect(p.round, isNull);
    expect(p.questionnairesAvailable, isFalse);
    expect(p.classMasters, isNotEmpty);
  });

  test('submit: incomplete is refused locally, success removes it', () async {
    final b = _Fake()..round = _round();
    final p = SchoolInfoProvider.withBackend(b);
    await p.fetch();
    final q = p.open(DateTime.now()).first;
    expect(await p.submit(q, {}), questionnaireIncompleteMessage);
    expect(b.sent, isEmpty);
    expect(await p.submit(q, {1: "5"}), isNull);
    expect(b.sent.single["TanarId"], q.teacherId);
    expect(p.open(DateTime.now()).length, 1);
  });

  test('KRÉTA refusal keeps it in the list', () async {
    final b = _Fake()
      ..round = _round()
      ..answer = (400, '{"uzenet": "Már kitöltötted."}');
    final p = SchoolInfoProvider.withBackend(b);
    await p.fetch();
    final q = p.open(DateTime.now()).first;
    expect(await p.submit(q, {1: "3"}), "Már kitöltötted.");
    expect(p.open(DateTime.now()).length, 2);
  });

  test('account switch hides data', () async {
    final b = _Fake()..round = _round();
    final p = SchoolInfoProvider.withBackend(b);
    await p.fetch();
    b.userId = "u2";
    expect(p.round, isNull);
    expect(p.classMasters, isEmpty);
  });
}
