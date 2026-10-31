import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging implementation of the Tinta push seam.
///
/// The Firebase project is not part of the source: it comes from build-time
/// defines (`--dart-define-from-file=push.json`, git-ignored). Without them
/// push stays off, so this build then behaves like the F-Droid one.
class TintaPush {
  static const bool supported = true;

  static const _options = (
    apiKey: String.fromEnvironment("TINTA_PUSH_API_KEY"),
    appId: String.fromEnvironment("TINTA_PUSH_APP_ID"),
    senderId: String.fromEnvironment("TINTA_PUSH_SENDER_ID"),
    projectId: String.fromEnvironment("TINTA_PUSH_PROJECT_ID"),
  );

  static bool get _configured =>
      _options.apiKey.isNotEmpty &&
      _options.appId.isNotEmpty &&
      _options.senderId.isNotEmpty &&
      _options.projectId.isNotEmpty;

  static bool _ready = false;

  static Future<bool> init({required Future<void> Function() onPush}) async {
    if (_ready) return true; // may be called again on app rebuilds
    if (!_configured) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _options.apiKey,
            appId: _options.appId,
            messagingSenderId: _options.senderId,
            projectId: _options.projectId,
          ),
        );
      }
      // Notification messages are shown by the system while the app is in
      // the background; in the foreground and on open we fetch right away.
      FirebaseMessaging.onMessage.listen((_) => onPush());
      FirebaseMessaging.onMessageOpenedApp.listen((_) => onPush());
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  static Future<String?> token() async {
    if (!_ready) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static Stream<String> get onTokenRefresh =>
      _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();
}
