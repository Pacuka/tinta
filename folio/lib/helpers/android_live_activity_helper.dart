import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:folio/api/providers/live_card_provider.dart';
import 'package:folio/helpers/subject.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/lesson.dart';

class AndroidLiveActivityHelper {
  static const _channel = MethodChannel('app.zan1456.folio/android_live_activity');

  static bool _active = false;

  /// Remaining seconds until [endDate], clamped to 0.
  static int _remainingSeconds(Map<String, String> data) {
    final endMs = int.tryParse(data['endDate'] ?? '');
    if (endMs == null || endMs == 0) return 0;
    final remaining = (endMs - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
    return remaining.clamp(0, 999999);
  }

  static Future<void> showOrUpdate({
    required LiveCardState state,
    required Map<String, String> data,
    required String type,
  }) async {
    if (!Platform.isAndroid) return;

    String title = '';
    String body = '';
    String? subText;

    final remainingSeconds = _remainingSeconds(data);

    switch (state) {
      case LiveCardState.duringLesson:
        final index = data['index'] ?? '';
        title = '${index.isNotEmpty ? "$index" : ""}${data['title'] ?? ''}';
        final room = data['subtitle'] ?? '';
        body = room.isNotEmpty ? room : (data['description'] ?? '');
        // No remaining text, no next subject during lesson
        break;

      case LiveCardState.duringBreak:
        final nextSubject = data['nextSubject'] ?? '';
        final nextRoom = data['nextRoom'] ?? '';
        title = type == 'hyper_os' && nextSubject.isNotEmpty
            ? 'Szünet • $nextSubject'
            : 'Szünet';
        body = type == 'hyper_os'
            ? nextRoom
            : (nextSubject.isNotEmpty
                ? '$nextSubject${nextRoom.isNotEmpty ? " – $nextRoom" : ""}'
                : '');
        // No remaining text label
        break;

      case LiveCardState.morning:
      case LiveCardState.afternoon:
      case LiveCardState.night:
        final nextSubject = data['nextSubject'] ?? '';
        if (nextSubject.isEmpty) {
          await cancel();
          return;
        }
        final nextRoom = data['nextRoom'] ?? '';
        title = type == 'hyper_os' ? 'Következő: $nextSubject' : 'Következő óra';
        body = type == 'hyper_os' ? nextRoom : nextSubject;
        if (type != 'hyper_os' && nextRoom.isNotEmpty) subText = nextRoom;
        break;

      default:
        await cancel();
        return;
    }

    try {
      if (type == 'hyper_os') {
        await _channel.invokeMethod('showOrUpdateHyperOs', {
          'title': title,
          'body': body,
          'subText': subText ?? '',
          'remainingSeconds': remainingSeconds,
        });
      } else {
        final content = liveContent(state, data);
        if (content == null) {
          await cancel();
          return;
        }
        // 'native' (régi érték) = automatikus: Android 16-on felső sávos élő
        // frissítés, régebbin hullámos csík. 'wavy' / 'android16' = kézzel.
        final live = {...content, 'mode': liveMode(type)};
        // A provider 5 mp-enként hív; a visszaszámlálást a rendszer ketyegteti,
        // a csíkot elég 30 mp-enként újrarajzolni, vagy ha változott a tartalom.
        final now = DateTime.now();
        final key = live.toString();
        if (_active &&
            key == _lastKey &&
            _lastSent != null &&
            now.difference(_lastSent!) < const Duration(seconds: 30)) {
          return;
        }
        await _channel.invokeMethod('showOrUpdateLive', live);
        _lastKey = key;
        _lastSent = now;
      }
      _active = true;
    } on PlatformException catch (e) {
      debugPrint('AndroidLiveActivityHelper error: $e');
    }
  }

  static String? _lastKey;

  /// A beállítás értékéből a natív oldal módja: auto / wavy / promoted.
  @visibleForTesting
  static String liveMode(String type) => switch (type) {
        'wavy' => 'wavy',
        'android16' => 'promoted',
        _ => 'auto',
      };
  static DateTime? _lastSent;

  /// Az élő értesítés tartalma (mi, hol, mi jön utána, mettől meddig).
  /// A `compact` az összecsukott nézet egyetlen sora (ott a csík miatt
  /// csak egy szövegsor fér el).
  /// `null`, ha nincs mit mutatni.
  @visibleForTesting
  static Map<String, Object>? liveContent(
      LiveCardState state, Map<String, String> data) {
    final startMs = int.tryParse(data['startDate'] ?? '') ?? 0;
    final endMs = int.tryParse(data['endDate'] ?? '') ?? 0;
    if (endMs == 0) return null;

    final nextSubject = data['nextSubject'] ?? '';
    final nextRoom = data['nextRoom'] ?? '';
    String place(String subject, String room) =>
        room.isEmpty ? subject : '$subject · $room';

    switch (state) {
      case LiveCardState.duringLesson:
        final room = (data['subtitle'] ?? '').replaceFirst('Terem: ', '').trim();
        return {
          'title': '${data['index'] ?? ''}${data['title'] ?? ''}'.trim(),
          'compact': place(
              '${data['index'] ?? ''}${data['title'] ?? ''}'.trim(), room),
          'body': room.isEmpty ? '' : 'Terem: $room',
          'next': nextSubject.isEmpty
              ? 'Ez a mai utolsó órád.'
              : 'Utána: ${place(nextSubject, nextRoom)}',
          'startMs': startMs,
          'endMs': endMs,
          'timerFormat': 'még %s',
        };
      case LiveCardState.duringBreak:
        return {
          'title': 'Szünet',
          'compact': nextSubject.isEmpty
              ? 'Szünet'
              : 'Szünet → ${place(nextSubject, nextRoom)}',
          'body': nextSubject.isEmpty
              ? ''
              : 'Következő: ${place(nextSubject, nextRoom)}',
          'next': data['description'] ?? '',
          'startMs': startMs,
          'endMs': endMs,
          'timerFormat': 'még %s',
        };
      case LiveCardState.morning:
      case LiveCardState.afternoon:
      case LiveCardState.night:
        if (nextSubject.isEmpty) return null;
        return {
          'title': 'Következő óra: $nextSubject',
          'compact': place(nextSubject, nextRoom),
          'body': nextRoom.isEmpty ? '' : 'Terem: $nextRoom',
          'next': '',
          'startMs': startMs,
          'endMs': endMs,
          'timerFormat': '%s múlva',
        };
      default:
        return null;
    }
  }

  static String? _lastPlan;

  /// Átadja a mai órák menetrendjét a natív oldalnak, ami időzítőkkel
  /// magától frissíti az élő értesítést akkor is, ha a Tinta nem fut.
  /// Csak akkor küld, ha a menetrend megváltozott.
  static Future<void> scheduleDay(
    List<Lesson> today, {
    required Duration delay,
    required String type,
  }) async {
    if (!Platform.isAndroid) return;
    if (type == 'hyper_os') return cancelSchedule();
    final plan = jsonEncode(dayPlan(today, delay: delay));
    final key = '$type|$plan';
    if (key == _lastPlan) return;
    try {
      await _channel.invokeMethod('scheduleDay', {
        'plan': plan,
        'mode': liveMode(type),
      });
      _lastPlan = key;
    } on PlatformException catch (e) {
      debugPrint('AndroidLiveActivityHelper scheduleDay error: $e');
    }
  }

  static Future<void> cancelSchedule() async {
    if (!Platform.isAndroid) return;
    _lastPlan = null;
    try {
      await _channel.invokeMethod('cancelSchedule');
    } on PlatformException catch (e) {
      debugPrint('AndroidLiveActivityHelper cancelSchedule error: $e');
    }
  }

  static String _subjectName(Lesson l) =>
      l.subject.renamedTo ?? ShortSubject.resolve(subject: l.subject).capital();

  /// A nap szakaszai (első óra előtti óra, órák, szünetek), mindegyik
  /// `from`/`to` epoch ms-mal és ugyanazokkal a mezőkkel, mint [liveContent].
  /// [today] már szűrve van (nincs elmaradt / üres óra).
  @visibleForTesting
  static List<Map<String, Object>> dayPlan(
    List<Lesson> today, {
    Duration delay = Duration.zero,
    String Function(Lesson)? name,
  }) {
    final subj = name ?? _subjectName;
    final lessons = [...today]..sort((a, b) => a.start.compareTo(b.start));
    int ms(DateTime d) => d.subtract(delay).millisecondsSinceEpoch;
    String room(Lesson l) => l.room.replaceAll('_', ' ').trim();
    String place(Lesson l) =>
        room(l).isEmpty ? subj(l) : '${subj(l)} · ${room(l)}';

    final out = <Map<String, Object>>[];
    for (var i = 0; i < lessons.length; i++) {
      final l = lessons[i];
      final next = i + 1 < lessons.length ? lessons[i + 1] : null;
      if (i == 0) {
        out.add({
          'from': ms(l.start.subtract(const Duration(hours: 1))),
          'to': ms(l.start),
          'title': 'Következő óra: ${subj(l)}',
          'compact': place(l),
          'body': room(l).isEmpty ? '' : 'Terem: ${room(l)}',
          'next': '',
          'startMs': 0,
          'endMs': ms(l.start),
          'timerFormat': '%s múlva',
        });
      }
      final title = '${l.lessonIndex.isEmpty ? '' : '${l.lessonIndex}. '}'
          '${subj(l)}';
      out.add({
        'from': ms(l.start),
        'to': ms(l.end),
        'title': title,
        'compact': room(l).isEmpty ? title : '$title · ${room(l)}',
        'body': room(l).isEmpty ? '' : 'Terem: ${room(l)}',
        'next': next == null ? 'Ez a mai utolsó órád.' : 'Utána: ${place(next)}',
        'startMs': ms(l.start),
        'endMs': ms(l.end),
        'timerFormat': 'még %s',
      });
      if (next != null && next.start.isAfter(l.end)) {
        out.add({
          'from': ms(l.end),
          'to': ms(next.start),
          'title': 'Szünet',
          'compact': 'Szünet → ${place(next)}',
          'body': 'Következő: ${place(next)}',
          'next': '',
          'startMs': ms(l.end),
          'endMs': ms(next.start),
          'timerFormat': 'még %s',
        });
      }
    }
    return out;
  }

  static Future<void> cancel() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancel');
    } on PlatformException catch (e) {
      debugPrint('AndroidLiveActivityHelper cancel error: $e');
    } finally {
      _active = false;
      _lastKey = null;
    }
  }

  static bool get isActive => _active;
}
