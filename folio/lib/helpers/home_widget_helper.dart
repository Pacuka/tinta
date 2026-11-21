import 'dart:io';

import 'dart:convert';

import 'package:flutter/material.dart';
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

  static String? _lastColors;

  /// The widget's colours from the app's current theme (palette, light or
  /// dark, Üveg's wallpaper colours). Sent only when they change.
  static Future<void> saveColors(ThemeData theme) async {
    if (!Platform.isAndroid) return;
    final json = jsonEncode(widgetColors(theme));
    if (json == _lastColors) return;
    _lastColors = json;
    try {
      await _channel.invokeMethod('colors', {'json': json});
    } catch (e) {
      _lastColors = null;
      debugPrint('HomeWidgetHelper colors error: $e');
    }
  }

  /// ARGB ints for TimetableWidget.kt (same roles as res/values/widget.xml).
  @visibleForTesting
  static Map<String, int> widgetColors(ThemeData theme) {
    final s = theme.colorScheme;
    final card = theme.cardColor;
    Color solid(Color c) => Color.alphaBlend(c, card);
    return {
      'bg': solid(theme.scaffoldBackgroundColor).toARGB32(),
      'card': card.withValues(alpha: 1).toARGB32(),
      'text': solid(s.onSurface).toARGB32(),
      'dim': solid(s.onSurfaceVariant).toARGB32(),
      'accent': solid(s.primary).toARGB32(),
      'container': solid(s.primaryContainer).toARGB32(),
    };
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
