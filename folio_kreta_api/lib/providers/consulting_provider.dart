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
  final hasBody = body != null && body.trim().isNotEmpty;
  if (status < 300) {
    if (!hasBody) return null;
    try {
      jsonDecode(body);
      return null;
    } catch (_) {
      // e.g. a maintenance page: we can't tell whether it went through
      return uncertainSubmitMessage;
    }
  }
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

/// What ConsultingProvider needs from the outside world (KRÉTA + cache),
/// so the provider's logic can be tested without a widget tree.
abstract class ConsultingBackend {
  /// The active account; null when logged out.
  String? get userId;
  bool get isDemo;

  /// GET Fogadoorak; null = request failed.
  Future<List?> list(DateTime from, DateTime to);

  /// POST a reservation: (status, body); status null = no response.
  Future<(int?, String?)> book(String slotId);

  /// DELETE a reservation: status, null = no response.
  Future<int?> cancel(String slotId);

  Future<List?> readCache(String userId);
  Future<void> writeCache(String userId, List json);
}

class _KretaConsultingBackend implements ConsultingBackend {
  final BuildContext _context;
  _KretaConsultingBackend(this._context);

  KretaClient get _kreta => Provider.of<KretaClient>(_context, listen: false);
  UserProvider get _user => Provider.of<UserProvider>(_context, listen: false);
  String get _iss => _user.user?.instituteCode ?? "";

  @override
  String? get userId => _user.id;

  @override
  bool get isDemo => _user.isDemo;

  @override
  Future<List?> list(DateTime from, DateTime to) async {
    try {
      final json =
          await _kreta.getAPI(KretaAPI.consultingHours(_iss, from, to));
      return json is List ? json : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<(int?, String?)> book(String slotId) async {
    final res = await _kreta.postAPI(
      KretaAPI.consultingReservation(_iss, slotId),
      rawResponse: true,
      json: false,
    );
    return res is http.Response ? (res.statusCode, res.body) : (null, null);
  }

  @override
  Future<int?> cancel(String slotId) async {
    final status =
        await _kreta.deleteAPI(KretaAPI.consultingReservation(_iss, slotId));
    return status is int ? status : null;
  }

  Future<File?> _file(String userId) async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File("${dir.path}/consulting_$userId.json");
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

/// Teacher consultation hours of the active account (student or parent).
/// Cached in a JSON file per user so the home feed has them offline.
class ConsultingProvider with ChangeNotifier {
  final ConsultingBackend _backend;

  ConsultingProvider({required BuildContext context})
      : _backend = _KretaConsultingBackend(context);

  @visibleForTesting
  ConsultingProvider.withBackend(this._backend);

  List<ConsultingHour> _hours = [];
  String? _userId;
  String? _error;

  /// Bumped by every fetch: only the newest one may change the list.
  int _gen = 0;
  int _running = 0;

  /// The list only ever belongs to the active account.
  List<ConsultingHour> get hours =>
      _backend.userId == _userId ? _hours : const [];
  bool get loading => _running > 0;
  String? get error => _backend.userId == _userId ? _error : null;

  void _switchUser() {
    final id = _backend.userId;
    if (id == _userId) return;
    _userId = id;
    _hours = [];
    _error = null;
    _gen++; // results for the previous account are dropped
    notifyListeners();
  }

  Future<void> restore() async {
    _switchUser();
    final userId = _userId;
    if (userId == null) return;
    final gen = _gen;
    final list = await _backend.readCache(userId);
    // A fetch (or account switch) since then wins over the cache.
    if (gen != _gen || list == null) return;
    try {
      _hours = list
          .whereType<Map>()
          .map(ConsultingHour.fromCacheJson)
          .toList();
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
    final (from, to) = consultingRange(DateTime.now());
    List? json;
    try {
      json = await _backend.list(from, to);
    } finally {
      _running--;
    }
    if (gen != _gen || userId != _userId) {
      notifyListeners();
      return;
    }
    List<ConsultingHour>? parsed;
    if (json != null) {
      try {
        parsed = ConsultingHour.listFromJson(json);
      } catch (_) {}
    }
    if (parsed != null) {
      _hours = parsed;
      _error = null;
      await _backend.writeCache(
          userId, parsed.map((h) => h.toCacheJson()).toList());
    } else {
      _error = networkErrorMessage;
    }
    notifyListeners();
  }

  /// The account that owns the list must still be the active one.
  bool get _sameUser => _userId != null && _backend.userId == _userId;

  Future<String?> book(ConsultingSlot slot, ConsultingHour hour) async {
    if (!_sameUser || slot.id.isEmpty) return consultingFailedMessage;
    final (status, body) = await _backend.book(slot.id);
    final error = parseConsultingError(status, body);
    if (error != consultingFailedMessage) await fetch();
    return error;
  }

  Future<String?> cancel(ConsultingSlot slot, ConsultingHour hour) async {
    if (!_sameUser || slot.id.isEmpty) return consultingFailedMessage;
    final status = await _backend.cancel(slot.id);
    final error = parseConsultingError(status, null);
    if (error != consultingFailedMessage) await fetch();
    return error;
  }
}
