import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:background_fetch/background_fetch.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/api/providers/status_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/models/user.dart';
import 'package:folio/models/config.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/absence.dart';
import 'package:folio_kreta_api/models/exam.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_kreta_api/providers/consulting_provider.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Local notifications for new KRÉTA data, without any push server.
///
/// Runs from background_fetch (every ~15 min, plus exact runs around each
/// lesson, see [nextLessonCheck]).
/// What was already seen is kept in a small state file; the first run only
/// records the current state, so old data never triggers notifications.
class UpdateNotifier {
  static const lessonCheckTaskId = "hu.pacuka.tinta.lessoncheck";
  static const _channelId = "tinta_updates";
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _pluginReady = false;
  static bool _running = false;

  /// Payload of the notification the user tapped (see
  /// [notificationPayload]); the app opens it and sets this back to null.
  static final tapped = ValueNotifier<String?>(null);

  /// Picks up the notification that launched the app from a cold start.
  static Future<void> checkLaunchTap() async {
    await _initPlugin();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      tapped.value = details!.notificationResponse?.payload;
    }
  }

  static Future<void> _initPlugin() async {
    if (_pluginReady) return;
    await _plugin.initialize(
      onDidReceiveNotificationResponse: (r) => tapped.value = r.payload,
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        // Permission is asked explicitly in requestPermission().
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _pluginReady = true;
  }

  /// Asks for the Android 13+ notification permission (no-op if granted).
  static Future<void> requestPermission() async {
    await _initPlugin();
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    }
  }

  static KretaClient? _appKreta;
  static UserProvider? _appUser;
  static SettingsProvider? _appSettings;

  /// The running app's client/user, so a background event while the app is
  /// alive reuses its tokens instead of refreshing them behind its back.
  static void attach({
    required KretaClient kreta,
    required UserProvider user,
    required SettingsProvider settings,
  }) {
    _appKreta = kreta;
    _appUser = user;
    _appSettings = settings;
  }

  /// Entry point for background_fetch events.
  static Future<void> onBackgroundEvent() async {
    if (_appKreta != null) {
      await check(kreta: _appKreta!, user: _appUser!, settings: _appSettings!);
    } else {
      await runHeadless();
    }
  }

  /// Background run while the app process is dead: builds its own client
  /// from the database. Only used when no app instance holds the tokens.
  static Future<void> runHeadless() async {
    DartPluginRegistrant.ensureInitialized();
    await Config.initDeviceUserAgent();
    final database = DatabaseProvider();
    await database.init();
    final settings = await database.query.getSettings(database);
    final user = await database.query.getUsers(settings);
    final kreta = KretaClient(
        settings: settings,
        user: user,
        database: database,
        status: StatusProvider());
    kreta.userAgent = settings.config.userAgent;
    await check(kreta: kreta, user: user, settings: settings);
  }

  /// Fetches the latest data and notifies about anything new.
  static Future<void> check({
    required KretaClient kreta,
    required UserProvider user,
    required SettingsProvider settings,
  }) async {
    if (_running) return;
    _running = true;
    try {
      await _check(kreta, user, settings);
    } catch (e) {
      // ignore: avoid_print
      print("ERROR UpdateNotifier: $e");
    } finally {
      _running = false;
    }
  }

  static Future<void> _check(KretaClient kreta, UserProvider userProvider,
      SettingsProvider settings) async {
    final user = userProvider.user;
    if (user == null || user.accessToken.trim().isEmpty) return;
    if (!settings.notificationsEnabled) return;

    if (user.accessTokenExpire.isBefore(DateTime.now())) {
      if (await kreta.refreshLogin() != 'success') return;
    }

    final iss = user.instituteCode;
    final state = await NotifyState.load(user.id);
    final notes = <_Note>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Grades
    final gradesJson = await kreta.getAPI(KretaAPI.grades(iss));
    if (gradesJson is List) {
      for (final g in gradesJson.cast<Map>().map(Grade.fromJson)) {
        if (!state.add("grades", g.id)) continue;
        if (!settings.notificationsGradesEnabled) continue;
        final value =
            g.value.value > 0 ? "${g.value.value}" : g.value.valueName;
        notes.add(_Note(
          "Új jegy: $value – ${g.subject.name}",
          [g.description, g.mode.description]
              .where((s) => s.trim().isNotEmpty)
              .join(" · "),
          notificationPayload("grade", g.id),
        ));
      }
    }

    // Exams
    final examsJson = await kreta.getAPI(KretaAPI.exams(iss));
    if (examsJson is List) {
      for (final e in examsJson.cast<Map>().map(Exam.fromJson)) {
        if (!state.add("exams", e.id)) continue;
        if (!settings.notificationsLessonsEnabled) continue;
        if (e.writeDate.isBefore(today)) continue;
        notes.add(_Note(
          "Új számonkérés: ${e.subject.name}",
          "${_day(e.writeDate)} · ${e.description.isNotEmpty ? e.description : (e.mode?.description ?? '')}",
          notificationPayload("exam", e.id),
        ));
      }
    }

    // Consultation hours (parents only, students get permission_denied)
    final (cFrom, cTo) = consultingRange(now);
    final consultingJson = user.role == Role.parent
        ? await kreta.getAPI(KretaAPI.consultingHours(iss, cFrom, cTo))
        : null;
    List<ConsultingHour>? consulting;
    try {
      if (consultingJson is List) {
        consulting = ConsultingHour.listFromJson(consultingJson);
      }
    } catch (_) {} // odd data must not stop the other notifications
    if (consulting != null) {
      for (final (title, body) in consultingNotes(consulting, state, now,
          enabled: settings.notificationsLessonsEnabled)) {
        notes.add(_Note(title, body, notificationPayload("consulting")));
      }
    }

    // Absences
    final absJson = await kreta.getAPI(KretaAPI.absences(iss));
    if (absJson is List) {
      for (final a in absJson.cast<Map>().map(Absence.fromJson)) {
        if (!state.add("absences", a.id)) continue;
        if (!settings.notificationsAbsencesEnabled) continue;
        notes.add(_Note(
          a.delay > 0 ? "Késés: ${a.delay} perc" : "Új hiányzás",
          "${_day(a.date)} · ${a.subject.name}",
          notificationPayload("absence", a.id),
        ));
      }
    }

    // Messages (inbox list only, no detail requests)
    final msgJson = await kreta.getAPI(KretaAPI.messages("beerkezett"));
    if (msgJson is List) {
      for (final m in msgJson.cast<Map>()) {
        final id = "${m["azonosito"]}";
        if (!state.add("messages", id)) continue;
        if (!settings.notificationsMessagesEnabled) continue;
        if (m["isElolvasva"] == true) continue;
        notes.add(_Note(
          "Új üzenet: ${m["uzenetFeladoNev"] ?? ""}".trim(),
          "${m["uzenetTargy"] ?? ""}",
          notificationPayload("message", id),
        ));
      }
    }

    // Homework (detail only when the list doesn't carry what we need)
    final hwJson = await kreta.getAPI(
        KretaAPI.homework(iss, start: today.subtract(const Duration(days: 7))));
    if (hwJson is List) {
      for (final h in hwJson.cast<Map>()) {
        final id = "${h["Uid"]}";
        final isNew = state.add("homework", id);
        final notify = settings.notificationsLessonsEnabled && !state.firstRun;
        final listed = "${h["Szoveg"] ?? ""}".trim().isNotEmpty;
        final due = DateTime.tryParse("${h["HataridoDatuma"]}")?.toLocal();
        final open = due != null && !due.isBefore(today);
        final detail = (isNew && notify) || (!listed && open)
            ? await kreta.getAPI(KretaAPI.homework(iss, id: id))
            : null;
        final source = detail is Map ? detail : (listed ? h : null);
        if (source == null) continue;
        // KRÉTA has no modification date, so compare with the last sighting.
        final edited = state.homeworkChanged(id,
            sha1.convert(utf8.encode(Homework.signature(source))).toString());
        if (!edited && !(isNew && notify)) continue;
        // The list may differ from the detail, the database has details.
        final full = detail is Map
            ? detail
            : await kreta.getAPI(KretaAPI.homework(iss, id: id));
        if (edited && full is Map) {
          await _saveHomeworkEdit(kreta, user.id, full);
        }
        if (!notify) continue;
        final hw = Homework.fromJson(full is Map ? full : source);
        notes.add(_Note(
          "${isNew ? "Új" : "Módosult a"} házi: ${hw.subject.name}",
          "Határidő: ${_day(hw.deadline)} · ${hw.content.replaceAll(RegExp(r'<[^>]*>'), '')}",
          notificationPayload("homework", id),
        ));
      }
    }

    // Timetable changes for today and tomorrow
    final lessonsJson = await kreta.getAPI(KretaAPI.timetable(iss,
        start: today, end: today.add(const Duration(days: 2))));
    final lessons = <Lesson>[];
    if (lessonsJson is List) {
      lessons.addAll(lessonsJson.cast<Map>().map(Lesson.fromJson));
      for (final l in lessons) {
        if (l.end.isBefore(now)) continue;
        final change = state.lessonChange(l);
        if (change == null || !settings.notificationsLessonsEnabled) continue;
        notes.add(_Note(change, "${_day(l.date)} · ${l.lessonIndex}. óra",
            notificationPayload("timetable")));
      }
    }

    if (!state.firstRun) await _show(notes);
    await state.save();
    await _scheduleNextCheck(lessons);
  }

  /// One-off exact run at the next moment KRÉTA data is likely to change,
  /// see [nextLessonCheck]. The ~15 min periodic fetch covers the rest.
  static Future<void> _scheduleNextCheck(List<Lesson> lessons) async {
    final now = DateTime.now();
    final at = nextLessonCheck(lessons, now);
    if (at == null) return;
    try {
      await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: lessonCheckTaskId,
        delay: at.difference(now).inMilliseconds,
        periodic: false,
        stopOnTerminate: false,
        enableHeadless: true,
        forceAlarmManager: true,
      ));
    } catch (_) {}
  }

  static Future<void> _show(List<_Note> notes) async {
    if (notes.isEmpty) return;
    await _initPlugin();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        "KRÉTA frissítések",
        channelDescription: "Új jegyek, üzenetek, órarend-változások",
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final n in notes.take(8)) {
      await _plugin.show(
        id: (n.title + n.body).hashCode & 0x7fffffff,
        title: n.title,
        body: n.body,
        notificationDetails: details,
        payload: n.payload,
      );
    }
    if (notes.length > 8) {
      await _plugin.show(
        id: 1,
        title: "És még ${notes.length - 8} újdonság",
        body: "Nyisd meg a Tintát a részletekért.",
        notificationDetails: details,
      );
    }
  }

  /// Stamps the change right away, the app may open hours later.
  static Future<void> _saveHomeworkEdit(
      KretaClient kreta, String userId, Map detail) async {
    final database = kreta.database;
    final saved = await database.userQuery.getHomework(userId: userId);
    final i = saved.indexWhere((h) => h.id == detail["Uid"]);
    if (i < 0) return;
    Homework.carryModified(saved[i].json, detail);
    saved[i] = Homework.fromJson(detail);
    await database.userStore.storeHomework(saved, userId: userId);
  }

  /// Things seen in the app don't need a notification later.
  static Future<void> markSeenInApp({
    required String userId,
    Iterable<String> grades = const [],
    Iterable<String> exams = const [],
    Iterable<String> absences = const [],
    Iterable<String> messages = const [],
    Iterable<String> homework = const [],
    Iterable<Lesson> lessons = const [],
    Iterable<String> consulting = const [],
  }) async {
    final state = await NotifyState.load(userId);
    if (state.firstRun) return; // first background run records everything
    recordSeenInApp(state,
        grades: grades,
        exams: exams,
        absences: absences,
        messages: messages,
        homework: homework,
        lessons: lessons,
        consulting: consulting);
    await state.save();
  }

  static String _day(DateTime d) => DateFormat("MMM d.", "hu").format(d);
}

/// Marks what the app already showed, so it isn't notified later.
void recordSeenInApp(
  NotifyState state, {
  Iterable<String> grades = const [],
  Iterable<String> exams = const [],
  Iterable<String> absences = const [],
  Iterable<String> messages = const [],
  Iterable<String> homework = const [],
  Iterable<Lesson> lessons = const [],
  Iterable<String> consulting = const [],
}) {
  grades.forEach((id) => state.add("grades", id));
  exams.forEach((id) => state.add("exams", id));
  absences.forEach((id) => state.add("absences", id));
  messages.forEach((id) => state.add("messages", id));
  homework.forEach((id) => state.add("homework", id));
  consulting.forEach((id) => state.add("consulting", id));
  for (final l in lessons) {
    state.lessonChange(l);
  }
}

/// Notifications for consultation hours: a new hour once, and a reminder on
/// the morning (from 07:00) of an own booking. Records what it has seen.
/// "type:id" for a notification, e.g. "grade:123"; [id] is left out for
/// targets that are a whole page ("timetable", "consulting").
String notificationPayload(String type, [String? id]) =>
    id == null ? type : "$type:$id";

/// Splits a payload made by [notificationPayload] into (type, id).
(String, String?) parseNotificationPayload(String payload) {
  final i = payload.indexOf(":");
  return i < 0
      ? (payload, null)
      : (payload.substring(0, i), payload.substring(i + 1));
}

/// When KRÉTA data most likely changes during a school day: shortly before
/// a lesson (cancellation, room change), a quarter hour in (attendance) and
/// just after it ends (grades). Returns the first such moment after [now],
/// or null when no lesson is left in [lessons].
DateTime? nextLessonCheck(List<Lesson> lessons, DateTime now) {
  final soon = now.add(const Duration(minutes: 1));
  final times = <DateTime>[
    for (final l in lessons)
      // KRÉTA also returns non-teaching days as lessons without a subject.
      if (l.subject.name.isNotEmpty && l.status?.name != "Elmaradt") ...[
        l.start.subtract(const Duration(minutes: 15)),
        l.start.add(const Duration(minutes: 15)),
        l.end.add(const Duration(minutes: 3)),
      ],
  ].where((t) => t.isAfter(soon)).toList()
    ..sort();
  return times.isEmpty ? null : times.first;
}

List<(String, String)> consultingNotes(
    List<ConsultingHour> hours, NotifyState state, DateTime now,
    {required bool enabled}) {
  final hm = DateFormat("HH:mm");
  final notes = <(String, String)>[];
  // First run after this feature arrived: just learn what already exists.
  final known = state.ids.containsKey("consulting");
  state.ids.putIfAbsent("consulting", () => {});
  // Hours far ahead are only recorded (they keep entering the 90-day window).
  final soon = now.add(const Duration(days: 14));
  for (final h in hours) {
    if (state.add("consulting", h.id) &&
        known &&
        enabled &&
        h.end.isAfter(now) &&
        h.start.isBefore(soon)) {
      notes.add((
        "Új fogadóóra: ${h.teacherName}",
        "${UpdateNotifier._day(h.start)} · ${hm.format(h.start)}–${hm.format(h.end)}",
      ));
    }
    final slot = h.myBooking;
    if (slot != null &&
        slot.start.year == now.year &&
        slot.start.month == now.month &&
        slot.start.day == now.day &&
        now.hour >= 7 &&
        now.isBefore(slot.start) &&
        state.add("consultingReminder", slot.id) &&
        enabled) {
      notes.add((
        "Ma fogadóóra: ${h.teacherName}",
        "${hm.format(slot.start)}${h.room.isNotEmpty ? " · ${h.room}" : ""}",
      ));
    }
  }
  return notes;
}

class _Note {
  final String title;
  final String body;

  /// What a tap opens, see [notificationPayload].
  final String? payload;
  _Note(this.title, this.body, [this.payload]);
}

/// What the notifier has already seen (persisted per user).
class NotifyState {
  final File file;
  final Map<String, Set<String>> ids;
  final Map<String, String> lessons; // lesson id -> signature
  final Map<String, String> homework; // homework id -> content signature
  final Set<String> days; // days whose timetable we already know
  final bool firstRun;

  NotifyState(this.file, this.ids, this.lessons, this.days, this.firstRun,
      {Map<String, String>? homework})
      : homework = homework ?? {};

  @visibleForTesting
  NotifyState.empty(this.file, {this.firstRun = false})
      : ids = {},
        lessons = {},
        homework = {},
        days = {};

  static Future<NotifyState> load(String userId) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/notify_state_$userId.json');
    if (!await file.exists()) return NotifyState(file, {}, {}, {}, true);
    try {
      final j = jsonDecode(await file.readAsString()) as Map;
      return NotifyState(
        file,
        (j["ids"] as Map)
            .map((k, v) => MapEntry(k as String, Set<String>.from(v as List))),
        Map<String, String>.from(j["lessons"] as Map),
        Set<String>.from(j["days"] as List),
        false,
        homework: Map<String, String>.from((j["homework"] ?? {}) as Map),
      );
    } catch (_) {
      return NotifyState(file, {}, {}, {}, true);
    }
  }

  /// True if [id] is new in [kind].
  bool add(String kind, String id) =>
      id.isNotEmpty && ids.putIfAbsent(kind, () => {}).add(id);

  /// Records [signature] and returns true if it differs from the previous one.
  /// The first sighting is never a change.
  bool homeworkChanged(String id, String signature) {
    final old = homework[id];
    homework[id] = signature;
    return old != null && old != signature;
  }

  /// Returns a notification title if the lesson changed in a way that
  /// matters (cancelled, substitute, room), and records its new state.
  String? lessonChange(Lesson l) {
    final sig =
        "${l.status?.name}|${l.substituteTeacher?.name ?? ''}|${l.room}";
    final day = DateFormat("yyyy-MM-dd").format(l.date);
    final old = lessons[l.id];
    final dayKnown = days.contains(day);
    lessons[l.id] = sig;
    days.add(day);
    if (firstRun || old == sig || (old == null && !dayKnown)) return null;

    final oldParts = (old ?? "||").split("|");
    final subject = l.subject.name;
    if (l.status?.name == "Elmaradt" && oldParts[0] != "Elmaradt") {
      return "Elmarad: $subject";
    }
    final sub = l.substituteTeacher?.name ?? '';
    if (sub.isNotEmpty && sub != oldParts[1]) {
      return "Helyettesítés: $subject – $sub";
    }
    if (old != null && l.room.isNotEmpty && l.room != oldParts[2]) {
      return "Teremcsere: $subject – ${l.room}";
    }
    return null;
  }

  Future<void> save() async {
    // Keep the file small: lesson signatures only for the last ~2 weeks.
    final cutoff = DateFormat("yyyy-MM-dd")
        .format(DateTime.now().subtract(const Duration(days: 14)));
    days.removeWhere((d) => d.compareTo(cutoff) < 0);
    if (lessons.length > 400) lessons.clear();
    if (homework.length > 400) homework.clear();
    await file.writeAsString(jsonEncode({
      "ids": ids.map((k, v) => MapEntry(k, v.toList())),
      "lessons": lessons,
      "homework": homework,
      "days": days.toList(),
    }));
  }
}
