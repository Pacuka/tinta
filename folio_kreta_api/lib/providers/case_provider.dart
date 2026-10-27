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

/// null = accepted; otherwise a message for the user.
String? parseSubmitError(int? status, String? body) {
  if (status == null) return "Nem sikerült elérni a KRÉTA-t.";
  dynamic decoded;
  if (body != null && body.trim().isNotEmpty) {
    try {
      decoded = jsonDecode(body);
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
  return null;
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
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _kreta.getAPI(KretaAPI.tmgiTypes),
        _kreta.getAPI(KretaAPI.caseTypes),
        _kreta.getAPI(KretaAPI.childData),
        _kreta.getAPI(KretaAPI.cases),
      ]);
      List<KretaType> types(dynamic v) =>
          v is List ? v.whereType<Map>().map(KretaType.fromJson).toList() : [];
      _justificationTypes = types(r[0]);
      _tmgiType = findTmgiType(types(r[1]));
      _child = r[2] is Map ? ChildData.fromJson(r[2]) : null;
      _cases = r[3] is List
          ? (r[3] as List)
              .whereType<Map>()
              .map(JustificationCase.fromJson)
              .toList()
          : [];
      _cases.sort((a, b) => (b.start ?? DateTime(0)).compareTo(a.start ?? DateTime(0)));
      if (_tmgiType == null || _justificationTypes.isEmpty) {
        _error = "Ennél az iskolánál nem érhető el az igazolás.";
      } else if (_child == null) {
        _error = "Nem sikerült betölteni a gyermek adatait.";
      }
    } catch (_) {
      _error = "Nem sikerült elérni a KRÉTA-t.";
    }
    _loading = false;
    notifyListeners();
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
    if (error == null) await load();
    return error;
  }
}
