// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:folio_kreta_api/models/exam.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:folio/api/client.dart';
import 'package:folio/api/providers/wear_extras.dart';
import 'package:folio/models/release.dart';
import 'package:path_provider/path_provider.dart';
import 'package:folio/helpers/average_helper.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_kreta_api/models/grade.dart';

/// The watch app's version from its `/folio/watch-version` message
/// (`{"name":"1.6.1","code":10}`), or null if it can't be read.
String? parseWatchVersion(String json) {
  try {
    final name = (jsonDecode(json) as Map)['name'];
    return name is String && name.isNotEmpty ? name : null;
  } catch (_) {
    return null;
  }
}

/// The ABIs the watch can run, best first (`"abis"` in the same message);
/// empty for watch apps that don't send them.
List<String> parseWatchAbis(String json) {
  try {
    final abis = (jsonDecode(json) as Map)['abis'];
    return abis is List ? abis.whereType<String>().toList() : const [];
  } catch (_) {
    return const [];
  }
}

/// Where a watch update is: download on the phone, transfer, then the
/// watch's own install prompt.
enum WearUpdateState { idle, downloading, sending, waitingForWatch, done, failed }

/// Serializes Kréta data and sends it to the paired WearOS watch via
/// Android's Wearable Data Layer API (method channel → WearSyncManager.kt).
///
/// Call [syncToWatch] after every [syncAll] and whenever timetable changes.
class WearProvider with ChangeNotifier {
  static const _channel = MethodChannel('app.zan1456.folio/wear_sync');

  bool _watchConnected = false;
  bool _syncEnabled = true;
  DateTime? _lastSync;
  String _lastTimetableHash = '';
  String _lastNotificationsHash = '';
  String _lastExtrasHash = '';
  String _lastTimetableJson = '';
  String _lastNotificationsJson = '';
  String _lastExtrasJson = '';

  /// Non-null when the watch has sent a pairing request and needs confirmation.
  String? _pendingPairCode;

  String? _watchVersion;
  List<String> _watchAbis = const [];
  WearUpdateState _updateState = WearUpdateState.idle;
  double _updateProgress = 0;
  String? _updateError;
  Timer? _updateTimeout;
  Timer? _updatePoll;
  Version? _updateTarget;

  /// Version of the Tinta app on the watch, once the watch has told it.
  String? get watchVersion => _watchVersion;
  WearUpdateState get updateState => _updateState;

  /// Download progress 0..1 while [updateState] is downloading.
  double get updateProgress => _updateProgress;
  String? get updateError => _updateError;

  bool get watchConnected => _watchConnected;
  bool get syncEnabled => _syncEnabled;
  DateTime? get lastSync => _lastSync;
  String? get pendingPairCode => _pendingPairCode;

  static WearProvider? _current;

  /// The last account was removed: clears what the watch was sent.
  static Future<void> forgetLoggedOut() async => _current?._forget();

  Future<void> _forget() async {
    _lastTimetableHash = '';
    _lastNotificationsHash = '';
    _lastExtrasHash = '';
    _lastTimetableJson = '';
    _lastNotificationsJson = '';
    _lastExtrasJson = '';
    try {
      await _channel.invokeMethod('sendLogout');
    } catch (_) {}
  }

  WearProvider() {
    _current = this;
    _channel.setMethodCallHandler(_handleNativeCall);
    _init();
  }

  // ── Initialization ───────────────────────────────────────────────────────

  Future<void> _init() async {
    await _loadSettings();
    await _checkConnection();
    await _scheduleMorningSync();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled =
          await _channel.invokeMethod<bool>('getSyncEnabled') ?? true;
      _syncEnabled = enabled;
    } catch (_) {}
  }

  // ── Connection ───────────────────────────────────────────────────────────

  Future<void> _checkConnection() async {
    try {
      final connected =
          await _channel.invokeMethod<bool>('isWatchConnected') ?? false;
      if (_watchConnected != connected) {
        _watchConnected = connected;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> refreshConnection() async {
    await _checkConnection();
    if (_watchConnected) await requestWatchVersion();
    return _watchConnected;
  }

  /// Asks the watch for its app version; the answer arrives as
  /// `onWatchVersion`.
  Future<void> requestWatchVersion() async {
    try {
      await _channel.invokeMethod('requestWatchVersion');
    } catch (_) {}
  }

  // ── Watch app update ─────────────────────────────────────────────────────

  /// Downloads the watch installer of [release] and sends it to the watch.
  /// The watch then shows the system install prompt; its answer arrives as
  /// `onWearUpdateResult`.
  Future<void> updateWatch(Release release) async {
    final asset = pickWearApk(release.downloads, abis: _watchAbis);
    if (asset == null) return _failUpdate('Nincs óra-app ebben a kiadásban.');
    _setUpdate(WearUpdateState.downloading, progress: 0);
    final File apk;
    try {
      final dir = await getTemporaryDirectory();
      apk = File('${dir.path}/folio_update_wear-${release.version}.apk');
      final response = await FilcAPI.downloadRelease(asset);
      if (response == null || response.statusCode != 200) {
        return _failUpdate('Nem sikerült letölteni.');
      }
      final total = response.contentLength ?? asset.size;
      var received = 0;
      final sink = apk.openWrite();
      await response.stream.map((chunk) {
        received += chunk.length;
        if (total > 0) {
          _updateProgress = received / total;
          notifyListeners();
        }
        return chunk;
      }).pipe(sink);
    } catch (_) {
      return _failUpdate('Nem sikerült letölteni.');
    }

    _setUpdate(WearUpdateState.sending);
    bool sent = false;
    try {
      sent = await _channel
              .invokeMethod<bool>('sendWearUpdate', {'path': apk.path}) ??
          false;
    } catch (_) {}
    if (!sent) return _failUpdate('Nem sikerült átküldeni az órára.');

    _setUpdate(WearUpdateState.waitingForWatch);
    _updateTarget = release.version;
    // No answer means the prompt was never confirmed (or the watch app was
    // closed and won't open again soon): let the user try again.
    _updateTimeout?.cancel();
    _updateTimeout = Timer(const Duration(minutes: 5), () {
      if (_updateState == WearUpdateState.waitingForWatch) {
        _failUpdate('Az óra nem válaszolt.');
      }
    });
    // The install restarts the watch app, which can cut off its "ok"
    // answer: also ask its version until it reports the new one.
    _updatePoll?.cancel();
    _updatePoll = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_updateState != WearUpdateState.waitingForWatch) {
        _updatePoll?.cancel();
      } else if (_watchConnected) {
        requestWatchVersion();
      }
    });
  }

  /// True once the watch reports [version] at least the one being sent.
  bool _reachedTarget(String version) {
    final target = _updateTarget;
    if (target == null) return false;
    return Version.fromString(version).compareTo(target) >= 0;
  }

  void _finishUpdate() {
    _updateTimeout?.cancel();
    _updatePoll?.cancel();
    _setUpdate(WearUpdateState.done);
  }

  void _setUpdate(WearUpdateState state, {double? progress}) {
    _updateState = state;
    if (progress != null) _updateProgress = progress;
    _updateError = null;
    notifyListeners();
  }

  void _failUpdate(String message) {
    _updateTimeout?.cancel();
    _updatePoll?.cancel();
    _updateState = WearUpdateState.failed;
    _updateError = message;
    notifyListeners();
  }

  // ── Public sync entry point ──────────────────────────────────────────────

  /// Called from [syncAll] after data fetch completes, and from the
  /// settings screen for manual sync. Reads current provider state via [ctx].
  Future<void> syncToWatch(BuildContext ctx) async {
    if (!_syncEnabled) return;

    final timetableJson = _buildTimetableJson(ctx);
    final notifJson = _buildNotificationsJson(ctx);

    final tHash = _hash(timetableJson);
    final nHash = _hash(notifJson);
    final extrasJson = _buildExtrasJson(ctx);
    final eHash = _hash(extrasJson);

    if (tHash != _lastTimetableHash) {
      _lastTimetableHash = tHash;
      await _sendTimetable(timetableJson);
    }
    if (nHash != _lastNotificationsHash) {
      _lastNotificationsHash = nHash;
      await _sendNotifications(notifJson);
    }
    if (eHash != _lastExtrasHash) {
      _lastExtrasHash = eHash;
      await _sendExtras(extrasJson);
    }
  }

  /// Force-send everything regardless of hash (used by manual sync button).
  Future<void> forceSyncToWatch(BuildContext ctx) async {
    if (!_syncEnabled) return;
    final timetableJson = _buildTimetableJson(ctx);
    final notifJson = _buildNotificationsJson(ctx);
    _lastTimetableHash = _hash(timetableJson);
    _lastNotificationsHash = _hash(notifJson);
    final extrasJson = _buildExtrasJson(ctx);
    _lastExtrasHash = _hash(extrasJson);
    await _sendTimetable(timetableJson);
    await _sendNotifications(notifJson);
    await _sendExtras(extrasJson);
  }

  // ── JSON builders ────────────────────────────────────────────────────────

  String _buildTimetableJson(BuildContext ctx) {
    try {
      final timetable = Provider.of<TimetableProvider>(ctx, listen: false);
      final homeworks =
          Provider.of<HomeworkProvider>(ctx, listen: false).homework;
      final exams = Provider.of<ExamProvider>(ctx, listen: false).exams;

      final today = DateTime.now();
      final week = Week.fromDate(today);
      // Send the full week so the watch can filter for the current day itself.
      // This prevents stale "today-only" cache from showing wrong data next day.
      // KRÉTA also returns non-teaching days (e.g. autumn break) as
      // subject-less "lessons"; the watch would show them as "0. 0:00".
      // Next week is only known from Friday, when the sync fetches it too.
      final lessons = [
        ...(timetable.lessons[week] ?? []).where((l) => l.subject.name.isNotEmpty),
        ...(timetable.lessons[week.next()] ?? [])
            .where((l) => l.subject.name.isNotEmpty),
      ]..sort((a, b) => a.start.compareTo(b.start));

      return jsonEncode(
          lessons.map((l) => _lessonToWearJson(l, homeworks, exams)).toList());
    } catch (e) {
      if (kDebugMode) print('WearProvider: buildTimetableJson error: $e');
      return '[]';
    }
  }

  Map<String, dynamic> _lessonToWearJson(
      Lesson lesson, List<Homework> homeworks, List<Exam> exams) {
    String status = 'normal';
    if (lesson.status?.name == 'Elmaradt' ||
        (lesson.status?.id.contains('Elmaradt') ?? false)) {
      status = 'cancelled';
    } else if (lesson.substituteTeacher != null) {
      status = 'substitution';
    }

    final subjectName = (lesson.subject.renamedTo?.isNotEmpty ?? false)
        ? lesson.subject.renamedTo!
        : lesson.subject.name;

    final teacherName = lesson.substituteTeacher != null
        ? ((lesson.substituteTeacher!.renamedTo?.isNotEmpty ?? false)
            ? lesson.substituteTeacher!.renamedTo!
            : lesson.substituteTeacher!.name)
        : ((lesson.teacher.renamedTo?.isNotEmpty ?? false)
            ? lesson.teacher.renamedTo!
            : lesson.teacher.name);

    final index =
        int.tryParse(lesson.lessonIndex.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // Match homework: assigned on the same day as this lesson, same subject.
    final lessonDay = DateTime(
        lesson.start.year, lesson.start.month, lesson.start.day);
    final hasHomework = homeworks.any((h) {
      final hDay =
          DateTime(h.lessonDate.year, h.lessonDate.month, h.lessonDate.day);
      return hDay == lessonDay && h.subject.name == lesson.subject.name;
    });

    // Match exam: written on the same day as this lesson, same subject.
    final hasExam = exams.any((e) {
      final eDay =
          DateTime(e.writeDate.year, e.writeDate.month, e.writeDate.day);
      return eDay == lessonDay && e.subject.name == lesson.subject.name;
    });

    return {
      'id': lesson.id,
      'subject': subjectName,
      'room': lesson.room,
      'teacher': teacherName,
      'start': lesson.start.millisecondsSinceEpoch,
      'end': lesson.end.millisecondsSinceEpoch,
      'lessonIndex': index,
      'status': status,
      'online': lesson.online,
      'hasHomework': hasHomework,
      'hasExam': hasExam,
    };
  }

  String _buildNotificationsJson(BuildContext ctx) {
    try {
      final grades = Provider.of<GradeProvider>(ctx, listen: false).grades;
      final messages =
          Provider.of<MessageProvider>(ctx, listen: false).messages;
      final notes = Provider.of<NoteProvider>(ctx, listen: false).notes;
      final absences =
          Provider.of<AbsenceProvider>(ctx, listen: false).absences;

      final items = <Map<String, dynamic>>[];

      for (final g in grades) {
        final value = g.value.valueName.isNotEmpty
            ? g.value.valueName
            : g.value.value > 0
                ? '${g.value.value}'
                : '';
        items.add({
          'id': g.id,
          'title': g.subject.name,
          'body':
              [g.description, value].where((s) => s.isNotEmpty).join(' – '),
          'type': 'grade',
          'gradeValue': g.value.value > 0 ? g.value.value : null,
          'timestamp': g.date.millisecondsSinceEpoch,
        });
      }

      for (final m in messages) {
        items.add({
          'id': '${m.id}',
          'title': m.subject,
          'body': m.author,
          'type': 'message',
          'timestamp': m.date.millisecondsSinceEpoch,
        });
      }

      for (final n in notes) {
        items.add({
          'id': n.id,
          'title': n.title,
          'body': n.content,
          'type': 'note',
          'timestamp': n.date.millisecondsSinceEpoch,
        });
      }

      for (final a in absences) {
        items.add({
          'id': a.id,
          'title': 'Hiányzás',
          'body': a.subject.name,
          'type': 'absence',
          'timestamp': a.date.millisecondsSinceEpoch,
        });
      }

      items.sort((a, b) =>
          (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      return jsonEncode(items.sublist(0, min(10, items.length)));
    } catch (e) {
      if (kDebugMode) print('WearProvider: buildNotificationsJson error: $e');
      return '[]';
    }
  }

  String _buildExtrasJson(BuildContext ctx) {
    try {
      final grades = Provider.of<GradeProvider>(ctx, listen: false).grades;
      final homeworks =
          Provider.of<HomeworkProvider>(ctx, listen: false).homework;
      final exams = Provider.of<ExamProvider>(ctx, listen: false).exams;
      final rounding =
          Provider.of<SettingsProvider>(ctx, listen: false).rounding;
      final midYear =
          grades.where((g) => g.type == GradeType.midYear).toList();
      return buildWearExtras(
        items: [
          for (final h in homeworks)
            WearTodoItem(
              id: h.id,
              type: 'homework',
              subject: wearSubjectName(h.subject),
              due: h.deadline,
            ),
          for (final e in exams)
            WearTodoItem(
              id: e.id,
              type: 'exam',
              subject: wearSubjectName(e.subject),
              due: e.writeDate,
            ),
        ],
        average: wearStudyAverage([
          for (final subject in midYear.map((g) => g.subject).toSet())
            if (AverageHelper.averageEvals(
                    midYear.where((g) => g.subject == subject).toList()) >
                0)
              (
                average: AverageHelper.averageEvals(
                    midYear.where((g) => g.subject == subject).toList()),
                threshold: (subject.customRounding ?? rounding.toDouble()) / 10,
              ),
        ]),
        now: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) print('WearProvider: buildExtrasJson error: $e');
      return '';
    }
  }

  // ── Sending ──────────────────────────────────────────────────────────────

  Future<void> _sendTimetable(String json) async {
    try {
      await _channel.invokeMethod('sendTimetable', {'json': json});
      _lastTimetableJson = json;
      _lastSync = DateTime.now();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('WearProvider: sendTimetable error: $e');
    }
  }

  Future<void> _sendNotifications(String json) async {
    try {
      await _channel.invokeMethod('sendNotifications', {'json': json});
      _lastNotificationsJson = json;
      _lastSync = DateTime.now();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('WearProvider: sendNotifications error: $e');
    }
  }

  Future<void> _sendExtras(String json) async {
    if (json.isEmpty) return;
    try {
      await _channel.invokeMethod('sendExtras', {'json': json});
      _lastExtrasJson = json;
    } catch (e) {
      if (kDebugMode) print('WearProvider: sendExtras error: $e');
    }
  }

  Future<void> _scheduleMorningSync() async {
    try {
      await _channel.invokeMethod('scheduleMorningSync');
    } catch (_) {}
  }

  Future<void> setSyncEnabled(bool enabled) async {
    _syncEnabled = enabled;
    try {
      await _channel.invokeMethod('setSyncEnabled', {'enabled': enabled});
    } catch (_) {}
    notifyListeners();
  }

  // ── Native call handler ──────────────────────────────────────────────────

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onConnectionChanged':
        _watchConnected = call.arguments as bool;
        notifyListeners();
        if (_watchConnected) await requestWatchVersion();
        break;
      case 'onSyncRequested':
        // Re-send last in-memory JSON if available; otherwise fall back to
        // native cached data (WearSyncManager reads phone SharedPreferences).
        if (_lastTimetableJson.isNotEmpty) {
          await _sendTimetable(_lastTimetableJson);
        }
        if (_lastNotificationsJson.isNotEmpty) {
          await _sendNotifications(_lastNotificationsJson);
        }
        if (_lastExtrasJson.isNotEmpty) {
          await _sendExtras(_lastExtrasJson);
        }
        if (_lastTimetableJson.isEmpty && _lastNotificationsJson.isEmpty) {
          try {
            await _channel.invokeMethod('sendCachedToWatch');
          } catch (_) {}
        }
        break;
      case 'onWatchVersion':
        final json = call.arguments as String? ?? '';
        final version = parseWatchVersion(json);
        _watchAbis = parseWatchAbis(json);
        if (version != null && version != _watchVersion) {
          _watchVersion = version;
          notifyListeners();
        }
        if (version != null &&
            _updateState == WearUpdateState.waitingForWatch &&
            _reachedTarget(version)) {
          _finishUpdate();
        }
        break;
      case 'onWearUpdateResult':
        final result = call.arguments as String? ?? '';
        if (result == 'ok') {
          _finishUpdate();
          await requestWatchVersion();
        } else {
          _failUpdate(result == 'error:aborted'
              ? 'A telepítést megszakították az órán.'
              : 'Az óra nem tudta telepíteni.');
        }
        break;
      case 'onPairRequest':
        // Watch sent its pairing code — store and notify UI.
        _pendingPairCode = call.arguments as String?;
        notifyListeners();
        break;
    }
  }

  /// Confirm pairing: validates the code the user typed and sends confirmation
  /// to the watch. Returns true if the code matches.
  Future<bool> confirmPairing(String enteredCode) async {
    if (_pendingPairCode == null || enteredCode != _pendingPairCode) {
      return false;
    }
    try {
      await _channel.invokeMethod(
          'sendPairConfirm', {'code': enteredCode});
    } catch (_) {}
    _pendingPairCode = null;
    notifyListeners();
    return true;
  }

  void dismissPairingRequest() {
    _pendingPairCode = null;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _hash(String data) =>
      md5.convert(utf8.encode(data)).toString();
}
