import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the phone runs Xiaomi HyperOS (read once at startup from the
/// `ro.mi.os.version.name` system property, e.g. "OS3.0").
///
/// Used by the Üveg theme: on HyperOS the sheets take HyperOS's own frosted
/// material (heavy blur + neutral grey, miuix `dialogGlass`); HyperOS phones
/// draw this themselves and handled it smoothly at 120 Hz (POCO X8 Pro,
/// 2026-11-16). Elsewhere the sheets stay a solid panel: the same blur
/// stuttered on a Redmi with a custom AOSP ROM.
class HyperOS {
  static const _channel = MethodChannel('app.zan1456.folio/system_ui');

  /// Null when not HyperOS, or not known yet / no native side (tests).
  static String? version;

  static bool get isHyperOS => version != null;

  static Future<void> init() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final v = await _channel.invokeMethod<String>('hyperOsVersion');
      version = (v == null || v.trim().isEmpty) ? null : v.trim();
    } catch (_) {
      // Older build or no native side: treat as not HyperOS (solid sheets).
    }
  }
}
