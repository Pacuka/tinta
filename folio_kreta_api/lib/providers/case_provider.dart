import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/justification.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// The "TMGI" (absence justification) entry of kerelemtipusok, if the school
/// offers it.
KretaType? findTmgiType(List<KretaType> types) {
  for (final t in types) {
    if (t.code == "TMGI") return t;
  }
  return null;
}

const networkErrorMessage = "Nem sikerült elérni a KRÉTA-t.";

/// The request may or may not have reached KRÉTA: never invite a blind resend.
const uncertainSubmitMessage =
    "Nem biztos, hogy megérkezett. Nézd meg a listát, mielőtt újraküldöd!";

/// null = accepted; otherwise a message for the user.
/// [status] null means no response at all (timeout / network error).
String? parseSubmitError(int? status, String? body) {
  if (status == null) return uncertainSubmitMessage;
  final hasBody = body != null && body.trim().isNotEmpty;
  dynamic decoded;
  bool isJson = false;
  if (hasBody) {
    try {
      decoded = jsonDecode(body);
      isJson = true;
    } catch (_) {}
  }
  if (decoded is Map) {
    final msg = decoded["uzenet"] ?? decoded["Message"] ?? decoded["message"];
    final code = decoded["hibakod"];
    if (msg is String && msg.isNotEmpty && (code != null || status >= 300)) {
      return msg;
    }
    if (code != null) return code.toString();
  }
  if (status >= 300) return "A KRÉTA hibát adott vissza ($status).";
  // 2xx with something that isn't JSON (e.g. a maintenance page).
  if (hasBody && !isJson) return uncertainSubmitMessage;
  return null;
}

class CaseLoadResult {
  final List<KretaType> justificationTypes;
  final KretaType? tmgiType;
  final ChildData? child;
  final List<JustificationCase> cases;
  final String? error;

  const CaseLoadResult({
    this.justificationTypes = const [],
    this.tmgiType,
    this.child,
    this.cases = const [],
    this.error,
  });
}

/// Turns the 4 GET results (null = request failed) into provider state.
CaseLoadResult interpretLoad(
    dynamic tmgiTypes, dynamic caseTypes, dynamic child, dynamic cases) {
  if (tmgiTypes is! List ||
      caseTypes is! List ||
      child is! Map ||
      cases is! List) {
    return const CaseLoadResult(error: networkErrorMessage);
  }
  List<KretaType> types(List v) =>
      v.whereType<Map>().map(KretaType.fromJson).toList();
  final justificationTypes = types(tmgiTypes);
  final tmgiType = findTmgiType(types(caseTypes));
  final list = cases.whereType<Map>().map(JustificationCase.fromJson).toList()
    ..sort((a, b) =>
        (b.start ?? DateTime(0)).compareTo(a.start ?? DateTime(0)));
  return CaseLoadResult(
    justificationTypes: justificationTypes,
    tmgiType: tmgiType,
    child: ChildData.fromJson(child),
    cases: list,
    error: tmgiType == null || justificationTypes.isEmpty
        ? "Ennél az iskolánál nem érhető el az igazolás."
        : null,
  );
}

/// Absence justifications (e-ügyintézés cases) of a parent account.
/// Kept in memory only.
class CaseProvider with ChangeNotifier {
  final BuildContext _context;

  CaseProvider({required BuildContext context}) : _context = context;

  List<JustificationCase> _cases = [];
  List<KretaType> _justificationTypes = [];
  KretaType? _tmgiType;
  ChildData? _child;
  bool _loading = false;
  String? _error;

  List<JustificationCase> get cases => _cases;
  List<KretaType> get justificationTypes => _justificationTypes;
  bool get loading => _loading;
  String? get error => _error;

  KretaClient get _kreta => Provider.of<KretaClient>(_context, listen: false);

  Future<void> load() async {
    // Never show the previous account's data while loading.
    _apply(const CaseLoadResult());
    _loading = true;
    notifyListeners();
    CaseLoadResult result;
    try {
      final r = await Future.wait([
        _kreta.getAPI(KretaAPI.tmgiTypes),
        _kreta.getAPI(KretaAPI.caseTypes),
        _kreta.getAPI(KretaAPI.childData),
        _kreta.getAPI(KretaAPI.cases),
      ]);
      result = interpretLoad(r[0], r[1], r[2], r[3]);
    } catch (_) {
      result = const CaseLoadResult(error: networkErrorMessage);
    }
    _apply(result);
    _loading = false;
    notifyListeners();
  }

  void _apply(CaseLoadResult r) {
    _justificationTypes = r.justificationTypes;
    _tmgiType = r.tmgiType;
    _child = r.child;
    _cases = r.cases;
    _error = r.error;
  }

  /// Sends the justification to the school. Returns null on success,
  /// otherwise a message for the user.
  Future<String?> submit({
    required KretaType justificationType,
    required DateTime start,
    required DateTime end,
    String reason = "",
  }) async {
    final caseType = _tmgiType;
    final child = _child;
    if (caseType == null || child == null) {
      return _error ?? "Nem sikerült betölteni az adatokat.";
    }
    final res = await _kreta.postAPI(
      KretaAPI.cases,
      rawResponse: true,
      body: jsonEncode(buildTmgiBody(
        child: child,
        caseType: caseType,
        justificationType: justificationType,
        start: start,
        end: end,
        reason: reason.trim(),
      )),
      headers: {"content-type": "application/json"},
    );
    final error = res is http.Response
        ? parseSubmitError(res.statusCode, res.body)
        : parseSubmitError(null, null);
    // Reload on success and when unsure, so the list shows what KRÉTA has.
    if (error == null || error == uncertainSubmitMessage) await load();
    return error;
  }
}
