import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:folio/api/providers/live_card_provider.dart';

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
