import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/models/user.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/program_event.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

const programNotLegalRepMessage =
    "Csak a törvényes képviselő engedélyezheti. Ezt a KRÉTA így tartja nyilván.";
const programTooLateMessage = "Erről már nem lehet dönteni.";
const programFailedMessage = "Nem sikerült. Próbáld újra később!";

/// null = saved; otherwise a message for the user.
/// [status] null means no response at all (timeout / network error).
String? parseProgramDecisionError(int? status, String? body) {
  if (status == null) return uncertainSubmitMessage;
  if (status < 300) return null;
  try {
    final decoded = jsonDecode(body ?? "");
    if (decoded is Map) {
      final text = "${decoded["uzenet"] ?? decoded["Message"] ?? ""}".trim();
      if (text.isNotEmpty && text.length < 200) return text;
    }
  } catch (_) {}
  return programFailedMessage;
}

/// What ProgramEventProvider needs from the outside world (KRÉTA + cache).
abstract class ProgramEventBackend {
  String? get userId;
  bool get isDemo;
  bool get isParent;

  /// TanuloAdatlap JSON of the active account (school modules, guardians).
  Map? get student;

  /// The logged-in guardian's own name (token `name` claim).
  String get guardianName;

  Future<List?> list(ProgramKind kind);

  /// POST GondviseloEngedelyezes: (status, body); status null = no response.
  Future<(int?, String?)> decide(ProgramKind kind, Map<String, Object> body);

  Future<List?> readCache(String userId);
  Future<void> writeCache(String userId, List json);
}

class _KretaProgramEventBackend implements ProgramEventBackend {
  final BuildContext _context;
  _KretaProgramEventBackend(this._context);

  KretaClient get _kreta => Provider.of<KretaClient>(_context, listen: false);
  UserProvider get _user => Provider.of<UserProvider>(_context, listen: false);
  String get _iss => _user.user?.instituteCode ?? "";

  @override
  String? get userId => _user.id;
  @override
  bool get isDemo => _user.isDemo;
  @override
  bool get isParent => _user.user?.role == Role.parent;
  @override
  Map? get student => _user.student?.json;
  @override
  String get guardianName => _user.user?.senderName ?? "";

  String _url(ProgramKind kind) => kind == ProgramKind.lep
      ? KretaAPI.lepEvents(_iss)
      : KretaAPI.nepEvents(_iss);

  @override
  Future<List?> list(ProgramKind kind) async {
    try {
      final json = await _kreta.getAPI(_url(kind));
      return json is List ? json : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<(int?, String?)> decide(
      ProgramKind kind, Map<String, Object> body) async {
    try {
      final res = await _kreta.postAPI(
        "${_url(kind)}/GondviseloEngedelyezes",
        body: jsonEncode(body),
        rawResponse: true,
        json: false,
      );
      return res is http.Response ? (res.statusCode, res.body) : (null, null);
    } catch (_) {
      return (null, null);
    }
  }

  Future<File?> _file(String userId) async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File("${dir.path}/programs_$userId.json");
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List?> readCache(String userId) async {
    try {
      final file = await _file(userId);
      if (file == null || !await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return json is List ? json : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeCache(String userId, List json) async {
    try {
      await (await _file(userId))?.writeAsString(jsonEncode(json));
    } catch (_) {}
  }
}

/// LÉP performances and NÉP programmes of the active account. Only fetched
/// when the school has the module switched on; parents can allow or refuse.
class ProgramEventProvider with ChangeNotifier {
  final ProgramEventBackend _backend;

  ProgramEventProvider({required BuildContext context})
      : _backend = _KretaProgramEventBackend(context);

  @visibleForTesting
  ProgramEventProvider.withBackend(this._backend);

  List<ProgramEvent> _events = [];
  String? _userId;
  String? _error;
  int _gen = 0;
  int _running = 0;

  bool get _active => _backend.userId == _userId;

  /// Newest first, like the official app.
  List<ProgramEvent> get events => _active ? _events : const [];
  bool get loading => _running > 0;
  String? get error => _active ? _error : null;

  bool get lepActive => schoolModuleActive(_backend.student, "LEP");
  bool get nepActive => schoolModuleActive(_backend.student, "NEP");

  /// Show the menu entry: a module is on, or we already have something.
  bool get available => lepActive || nepActive || events.isNotEmpty;

  bool get isParent => _backend.isParent;

  /// Programmes waiting for the parent's decision.
  int pendingCount(DateTime now) => !isParent
      ? 0
      : events.where((e) => e.permitted == null && e.canDecide(now)).length;

  void _switchUser() {
    final id = _backend.userId;
    if (id == _userId) return;
    _userId = id;
    _events = [];
    _error = null;
    _gen++;
    notifyListeners();
  }

  void _sort() => _events.sort((a, b) => b.start.compareTo(a.start));

  Future<void> restore() async {
    _switchUser();
    final userId = _userId;
    if (userId == null) return;
    final gen = _gen;
    final json = await _backend.readCache(userId);
    if (gen != _gen || json == null || _events.isNotEmpty) return;
    _events = json
        .whereType<Map>()
        .map(ProgramEvent.fromCacheJson)
        .nonNulls
        .toList();
    _sort();
    notifyListeners();
  }

  Future<void> fetch() async {
    _switchUser();
    final userId = _userId;
    if (userId == null || _backend.isDemo) return;
    final kinds = [
      if (lepActive) ProgramKind.lep,
      if (nepActive) ProgramKind.nep,
    ];
    if (kinds.isEmpty) return;
    final gen = ++_gen;
    _running++;
    notifyListeners();
    final lists = <ProgramKind, List?>{};
    try {
      for (final k in kinds) {
        lists[k] = await _backend.list(k);
      }
    } finally {
      _running--;
    }
    if (gen != _gen || userId != _userId) {
      notifyListeners();
      return;
    }
    if (lists.values.any((l) => l == null)) _error = networkErrorMessage;
    final fresh = <ProgramEvent>[];
    for (final k in ProgramKind.values) {
      final l = lists[k];
      fresh.addAll(l != null
          // a failed list keeps what we had for that kind
          ? ProgramEvent.listFromJson(k, l)
          : _events.where((e) => e.kind == k));
    }
    if (!lists.values.any((l) => l == null)) _error = null;
    _events = fresh;
    _sort();
    await _backend.writeCache(
        userId, _events.map((e) => e.toCacheJson()).toList());
    notifyListeners();
  }

  /// Why the parent can't decide right now, or null if they can.
  String? blockReason(ProgramEvent e, DateTime now) {
    if (!e.canDecide(now)) return programTooLateMessage;
    final rep = isLegalRepresentative(_backend.student, _backend.guardianName);
    if (!_backend.isParent || rep == false) return programNotLegalRepMessage;
    return null;
  }

  /// Sends the decision; null = saved.
  Future<String?> decide(ProgramEvent e, bool allow) async {
    final userId = _userId;
    if (userId == null || !_active) return programFailedMessage;
    final blocked = blockReason(e, DateTime.now());
    if (blocked != null) return blocked;
    final (status, body) = await _backend.decide(e.kind, e.decisionBody(allow));
    final error = parseProgramDecisionError(status, body);
    if (error == null && _active) {
      final i = _events.indexWhere((x) => x.kind == e.kind && x.id == e.id);
      if (i >= 0) _events[i] = _events[i].withDecision(allow);
      await _backend.writeCache(
          userId, _events.map((x) => x.toCacheJson()).toList());
      notifyListeners();
    }
    if (error == uncertainSubmitMessage) await fetch();
    return error;
  }
}
