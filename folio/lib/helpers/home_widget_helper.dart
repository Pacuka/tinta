import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:folio/helpers/update_notifier.dart';

/// Android home/lock screen timetable widget (TimetableWidget.kt).
class HomeWidgetHelper {
  static const _channel = MethodChannel('app.zan1456.folio/home_widget');

  /// [json] is the lesson list built by WearProvider.timetableJson.
  static Future<void> save(String json) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('save', {'json': json});
    } catch (e) {
      debugPrint('HomeWidgetHelper save error: $e');
    }
  }

  /// Widget taps arrive like notification taps (same payloads), so the
  /// navigation screen opens them via [UpdateNotifier.tapped].
  static Future<void> listenTaps() async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) {
        UpdateNotifier.tapped.value = call.arguments as String;
      }
    });
    try {
      final target = await _channel.invokeMethod<String>('takeLaunchTap');
      if (target != null) UpdateNotifier.tapped.value = target;
    } catch (_) {}
  }

  static Future<void> clear() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('clear');
    } catch (_) {}
  }
}
