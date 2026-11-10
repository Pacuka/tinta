import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS "Reduce Transparency" (Settings → Accessibility → Display & Text
/// Size). Flutter doesn't expose it, so AppDelegate.swift reports it.
/// Always false on other platforms.
class ReduceTransparency {
  static const _channel = MethodChannel('app.zan1456.folio/accessibility');

  static final ValueNotifier<bool> enabled = ValueNotifier(false);

  static Future<void> init() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'reduceTransparencyChanged' && call.arguments is bool) {
        enabled.value = call.arguments as bool;
      }
    });
    try {
      enabled.value =
          await _channel.invokeMethod<bool>('reduceTransparency') ?? false;
    } catch (_) {
      // Older build or no native side: keep the glass.
    }
  }
}
