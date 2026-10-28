import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/class_master.dart';
import 'package:folio_kreta_api/models/program_event.dart';
import 'package:folio_kreta_api/models/questionnaire.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:folio_kreta_api/providers/program_event_provider.dart'
    show parseProgramDecisionError, programFailedMessage;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

const questionnaireIncompleteMessage = "Minden kérdésre válaszolj!";

/// What SchoolInfoProvider needs from the outside world (KRÉTA + cache).
abstract class SchoolInfoBackend {
  String? get userId;
  bool get isDemo;

  /// TanuloAdatlap JSON of the active account (school modules).
  Map? get student;

  Future<Map?> questionnaires();
  Future<(int?, String?)> submitQuestionnaire(Map<String, Object> body);
  Future<List?> groups();
  Future<List?> classMasters(String uids);

  Future<Map?> readCache(String userId);
  Future<void> writeCache(String userId, Map json);
}

class _KretaSchoolInfoBackend implements SchoolInfoBackend {
  final BuildContext _context;
  _KretaSchoolInfoBackend(this._context);

  KretaClient get _kreta => Provider.of<KretaClient>(_context, listen: false);
  UserProvider get _user => Provider.of<UserProvider>(_context, listen: false);
  String get _iss => _user.user?.instituteCode ?? "";

  @override
  String? get userId => _user.id;
  @override
  bool get isDemo => _user.isDemo;
  @override
  Map? get student => _user.student?.json;

  Future<T?> _get<T>(String url) async {
    try {
      final json = await _kreta.getAPI(url);
      return json is T ? json : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map?> questionnaires() => _get<Map>(KretaAPI.questionnaires(_iss));

  @override
  Future<(int?, String?)> submitQuestionnaire(Map<String, Object> body) async {
    try {
      final res = await _kreta.postAPI(
        KretaAPI.questionnaire(_iss),
        body: jsonEncode(body),
        rawResponse: true,
        json: false,
      );
      return res is http.Response ? (res.statusCode, res.body) : (null, null);
    } catch (_) {
      return (null, null);
    }
  }

  @override
  Future<List?> groups() => _get<List>(KretaAPI.groups(_iss));

  @override
  Future<List?> classMasters(String uids) =>
      _get<List>(KretaAPI.classMasters(_iss, uids));

  Future<File?> _file(String userId) async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File("${dir.path}/school_info_$userId.json");
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map?> readCache(String userId) async {
    try {
      final file = await _file(userId);
      if (file == null || !await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return json is Map ? json : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeCache(String userId, Map json) async {
    try {
      await (await _file(userId))?.writeAsString(jsonEncode(json));
    } catch (_) {}
  }
}

/// Teacher questionnaires (PedTér) and the homeroom teacher's contacts of
/// the active account.
class SchoolInfoProvider with ChangeNotifier {
  final SchoolInfoBackend _backend;

  SchoolInfoProvider({required BuildContext context})
      : _backend = _KretaSchoolInfoBackend(context);

  @visibleForTesting
  SchoolInfoProvider.withBackend(this._backend);

  QuestionnaireRound? _round;
  List<ClassMaster> _masters = [];
  String? _userId;
  String? _error;
  int _gen = 0;
  int _running = 0;

  bool get _active => _backend.userId == _userId;

  QuestionnaireRound? get round => _active ? _round : null;
  List<ClassMaster> get classMasters => _active ? _masters : const [];
  bool get loading => _running > 0;
  String? get error => _active ? _error : null;

  bool get questionnairesActive =>
      schoolModuleActive(_backend.student, "PedterKerdoiv");

  /// Questionnaires that can be filled in now.
  List<TeacherQuestionnaire> open(DateTime now) {
    final r = round;
    if (r == null || !r.isOpen(now)) return const [];
    return r.items
        .where((q) => q.deadline == null || now.isBefore(q.deadline!))
        .toList();
  }

  bool get questionnairesAvailable =>
      questionnairesActive || (round?.items.isNotEmpty ?? false);

  void _switchUser() {
    final id = _backend.userId;
    if (id == _userId) return;
    _userId = id;
    _round = null;
    _masters = [];
    _error = null;
    _gen++;
    notifyListeners();
  }

  Map _cacheJson() => {
        if (_round != null) "questionnaires": _round!.toJson(),
        "classMasters": _masters.map((m) => m.toJson()).toList(),
      };

  Future<void> restore() async {
    _switchUser();
    final userId = _userId;
    if (userId == null) return;
    final gen = _gen;
    final json = await _backend.readCache(userId);
    if (gen != _gen || json == null) return;
    try {
      if (_round == null && json["questionnaires"] is Map) {
        _round = QuestionnaireRound.fromJson(json["questionnaires"]);
      }
      if (_masters.isEmpty && json["classMasters"] is List) {
        _masters = (json["classMasters"] as List)
            .whereType<Map>()
            .map(ClassMaster.fromJson)
            .nonNulls
            .toList();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetch() async {
    _switchUser();
    final userId = _userId;
    if (userId == null || _backend.isDemo) return;
    final gen = ++_gen;
    _running++;
    notifyListeners();
    Map? q;
    List? masters;
    var failed = false;
    try {
      if (questionnairesActive) {
        q = await _backend.questionnaires();
        failed = q == null;
      }
      final groups = await _backend.groups();
      final uids = groups == null ? "" : classMasterUids(groups);
      if (uids.isNotEmpty) masters = await _backend.classMasters(uids);
    } finally {
      _running--;
    }
    if (gen != _gen || userId != _userId) {
      notifyListeners();
      return;
    }
    if (q != null) _round = QuestionnaireRound.fromJson(q);
    if (masters != null) {
      _masters =
          masters.whereType<Map>().map(ClassMaster.fromJson).nonNulls.toList();
    }
    _error = failed ? networkErrorMessage : null;
    await _backend.writeCache(userId, _cacheJson());
    notifyListeners();
  }

  /// Sends one questionnaire; null = sent (it then leaves the list).
  Future<String?> submit(
      TeacherQuestionnaire q, Map<int, String> answers) async {
    final userId = _userId;
    if (userId == null || !_active) return programFailedMessage;
    if (!q.isComplete(answers)) return questionnaireIncompleteMessage;
    final (status, body) =
        await _backend.submitQuestionnaire(q.submitBody(answers));
    final error = parseProgramDecisionError(status, body);
    if (error == null && _active && _round != null) {
      _round = QuestionnaireRound(
        start: _round!.start,
        end: _round!.end,
        items: _round!.items.where((x) => x.teacherId != q.teacherId).toList(),
      );
      await _backend.writeCache(userId, _cacheJson());
      notifyListeners();
    }
    if (error == uncertainSubmitMessage) await fetch();
    return error;
  }
}
