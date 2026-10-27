import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

const consultingTakenMessage =
    "Ezt az időpontot közben elvitték, válassz másikat!";
const consultingAlreadyMessage = "Már van foglalásod ennél a tanárnál.";
const consultingFailedMessage = "Nem sikerült. Próbáld újra később!";

/// The list we ask KRÉTA for: yesterday .. today + 90 days (local dates).
(DateTime, DateTime) consultingRange(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return (
    today.subtract(const Duration(days: 1)),
    today.add(const Duration(days: 90)),
  );
}

/// null = booked/cancelled; otherwise a message for the user.
/// [status] null means no response at all (timeout / network error).
String? parseConsultingError(int? status, String? body) {
  if (status == null) return uncertainSubmitMessage;
  if (status < 300) return null;
  String text = "";
  try {
    final decoded = jsonDecode(body ?? "");
    if (decoded is Map) {
      text = "${decoded["hibakod"] ?? ""} ${decoded["uzenet"] ?? ""}";
    }
  } catch (_) {}
  final t = text.toLowerCase();
  if (t.contains("marjelentkezett") || t.contains("ön már foglalt")) {
    return consultingAlreadyMessage;
  }
  if (t.contains("foglalt")) return consultingTakenMessage;
  return consultingFailedMessage;
}

/// Teacher consultation hours of the active account (student or parent).
/// Cached in a JSON file per user so the home feed has them offline.
class ConsultingProvider with ChangeNotifier {
  final BuildContext _context;

  ConsultingProvider({required BuildContext context}) : _context = context;

  List<ConsultingHour> _hours = [];
  String? _userId;
  bool _loading = false;
  String? _error;

  List<ConsultingHour> get hours => _hours;
  bool get loading => _loading;
  String? get error => _error;

  KretaClient get _kreta => Provider.of<KretaClient>(_context, listen: false);
  UserProvider get _user => Provider.of<UserProvider>(_context, listen: false);

  /// Never show the previous account's list.
  bool _switchUser() {
    final id = _user.id;
    if (id == _userId) return false;
    _userId = id;
    _hours = [];
    _error = null;
    notifyListeners();
    return true;
  }

  Future<File?> _cacheFile(String userId) async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File("${dir.path}/consulting_$userId.json");
    } catch (_) {
      return null;
    }
  }

  Future<void> restore() async {
    _switchUser();
    final userId = _userId;
    if (userId == null) return;
    final file = await _cacheFile(userId);
    if (file == null || !await file.exists()) return;
    try {
      final list = jsonDecode(await file.readAsString());
      // The account may have changed while reading.
      if (userId != _userId || list is! List || _hours.isNotEmpty) return;
      _hours = list
          .whereType<Map>()
          .map(ConsultingHour.fromCacheJson)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetch() async {
    _switchUser();
    final user = _user.user;
    final userId = _userId;
    if (user == null || userId == null) return;
    if (_user.isDemo) return; // no consultation hours in demo mode
    _loading = true;
    notifyListeners();
    final (from, to) = consultingRange(DateTime.now());
    dynamic json;
    try {
      json = await _kreta
          .getAPI(KretaAPI.consultingHours(user.instituteCode, from, to));
    } catch (_) {}
    if (userId != _userId) return;
    _loading = false;
    if (json is List) {
      _hours = ConsultingHour.listFromJson(json);
      _error = null;
      final file = await _cacheFile(userId);
      try {
        await file?.writeAsString(
            jsonEncode(_hours.map((h) => h.toCacheJson()).toList()));
      } catch (_) {}
    } else {
      _error = networkErrorMessage;
    }
    notifyListeners();
  }

  Future<String?> book(ConsultingSlot slot, ConsultingHour hour) async {
    final user = _user.user;
    if (user == null) return consultingFailedMessage;
    final res = await _kreta.postAPI(
      KretaAPI.consultingReservation(user.instituteCode, slot.id),
      rawResponse: true,
      json: false,
    );
    final error = res is http.Response
        ? parseConsultingError(res.statusCode, res.body)
        : parseConsultingError(null, null);
    if (error == null || error == uncertainSubmitMessage) await fetch();
    return error;
  }

  Future<String?> cancel(ConsultingSlot slot, ConsultingHour hour) async {
    final user = _user.user;
    if (user == null) return consultingFailedMessage;
    final status = await _kreta.deleteAPI(
        KretaAPI.consultingReservation(user.instituteCode, slot.id));
    final error = parseConsultingError(status is int ? status : null, null);
    if (error == null || error == uncertainSubmitMessage) await fetch();
    return error;
  }
}
