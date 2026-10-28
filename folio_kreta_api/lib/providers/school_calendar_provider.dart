import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/school_calendar.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// What SchoolCalendarProvider needs from the outside world (KRÉTA + cache),
/// so its logic can be tested without a widget tree.
abstract class SchoolCalendarBackend {
  /// The active account; null when logged out.
  String? get userId;
  bool get isDemo;

  /// GET TanevRendjeElemek; null = request failed.
  Future<List?> calendar();

  /// GET Hetirendek/Orarendi; null = request failed.
  Future<List?> weeks(DateTime from, DateTime to);

  Future<Map?> readCache(String userId);
  Future<void> writeCache(String userId, Map json);
}

class _KretaSchoolCalendarBackend implements SchoolCalendarBackend {
  final BuildContext _context;
  _KretaSchoolCalendarBackend(this._context);

  KretaClient get _kreta => Provider.of<KretaClient>(_context, listen: false);
  UserProvider get _user => Provider.of<UserProvider>(_context, listen: false);
  String get _iss => _user.user?.instituteCode ?? "";

  @override
  String? get userId => _user.id;

  @override
  bool get isDemo => _user.isDemo;

  Future<List?> _list(String url) async {
    try {
      final json = await _kreta.getAPI(url);
      return json is List ? json : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List?> calendar() => _list(KretaAPI.schoolCalendar(_iss));

  @override
  Future<List?> weeks(DateTime from, DateTime to) =>
      _list(KretaAPI.schoolWeeks(_iss, from, to));

  Future<File?> _file(String userId) async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File("${dir.path}/school_calendar_$userId.json");
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

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// "Tanév rendje" (whole school year) and the A/B week of each school week
/// for the active account. Cached in one JSON file per user.
class SchoolCalendarProvider with ChangeNotifier {
  final SchoolCalendarBackend _backend;

  SchoolCalendarProvider({required BuildContext context})
      : _backend = _KretaSchoolCalendarBackend(context);

  @visibleForTesting
  SchoolCalendarProvider.withBackend(this._backend);

  List<SchoolCalendarDay> _days = [];
  final Map<DateTime, SchoolWeek> _weeks = {};
  final Set<DateTime> _weeksAsked = {};
  String? _userId;
  String? _error;

  /// Bumped by every account switch: older results are dropped.
  int _gen = 0;
  int _running = 0;

  bool get _active => _backend.userId == _userId;

  List<SchoolCalendarDay> get days => _active ? _days : const [];
  List<SchoolCalendarItem> get items => buildSchoolCalendar(days);
  bool get loading => _running > 0;
  String? get error => _active ? _error : null;

  /// The school week containing [day], if KRÉTA told us about it.
  SchoolWeek? weekOf(DateTime day) {
    if (!_active) return null;
    final d = _day(day);
    for (final w in _weeks.values) {
      if (!d.isBefore(w.start) && !d.isAfter(w.end)) return w;
    }
    return null;
  }

  void _switchUser() {
    final id = _backend.userId;
    if (id == _userId) return;
    _userId = id;
    _days = [];
    _weeks.clear();
    _weeksAsked.clear();
    _error = null;
    _gen++;
    notifyListeners();
  }

  Map _cacheJson() => {
        "days": _days.map((d) => d.toCacheJson()).toList(),
        "weeks": _weeks.values.map((w) => w.toCacheJson()).toList(),
      };

  Future<void> _save(String userId) =>
      _backend.writeCache(userId, _cacheJson());

  Future<void> restore() async {
    _switchUser();
    final userId = _userId;
    if (userId == null) return;
    final gen = _gen;
    final json = await _backend.readCache(userId);
    if (gen != _gen || json == null) return;
    try {
      if (_days.isEmpty && json["days"] is List) {
        _days = SchoolCalendarDay.listFromJson(json["days"]);
      }
      for (final w in (json["weeks"] as List? ?? const []).whereType<Map>()) {
        final week = SchoolWeek.fromJson(w);
        _weeks.putIfAbsent(week.start, () => week);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// The whole school year; also refreshes the week around [now].
  Future<void> fetch({DateTime? now}) async {
    _switchUser();
    final userId = _userId;
    if (userId == null || _backend.isDemo) return;
    final gen = _gen;
    _running++;
    notifyListeners();
    List? json;
    try {
      json = await _backend.calendar();
    } finally {
      _running--;
    }
    if (gen != _gen) {
      notifyListeners();
      return;
    }
    if (json != null) {
      _days = SchoolCalendarDay.listFromJson(json);
      _error = null;
      await _save(userId);
    } else {
      _error = networkErrorMessage;
    }
    notifyListeners();
    await fetchWeek(now ?? DateTime.now(), force: true);
  }

  /// Asks KRÉTA for the week containing [day] (and the one after it),
  /// once per week per launch unless [force].
  Future<void> fetchWeek(DateTime day, {bool force = false}) async {
    _switchUser();
    final userId = _userId;
    if (userId == null || _backend.isDemo) return;
    final d = _day(day);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    if (!force && !_weeksAsked.add(monday)) return;
    _weeksAsked.add(monday);
    final gen = _gen;
    final json = await _backend.weeks(monday, monday.add(const Duration(days: 14)));
    if (gen != _gen || json == null) return;
    var changed = false;
    for (final w in json.whereType<Map>()) {
      try {
        final week = SchoolWeek.fromJson(w);
        _weeks[week.start] = week;
        changed = true;
      } catch (_) {}
    }
    if (changed) {
      await _save(userId);
      notifyListeners();
    }
  }
}
