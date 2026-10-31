/// Push messaging seam for Tinta.
///
/// This is the default, dependency-free implementation used by the F-Droid
/// build: push is never available. The Firebase build replaces this package
/// with `../tinta_push_firebase` (same package name, same API) through
/// `pubspec_overrides.yaml`, see `folio/tool/README.md`.
class TintaPush {
  /// Whether this build can receive push messages at all.
  static const bool supported = false;

  /// Sets up push; [onPush] runs when a push message arrives while the app
  /// is running or is opened from one. Returns false when push is off.
  static Future<bool> init({required Future<void> Function() onPush}) async =>
      false;

  /// Device token to register with the push sender, null when unavailable.
  static Future<String?> token() async => null;

  /// New device tokens (the sender must be updated with them).
  static Stream<String> get onTokenRefresh => const Stream.empty();
}
