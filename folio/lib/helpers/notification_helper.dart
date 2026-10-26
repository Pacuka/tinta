// Tinta: the old Firebase (FCM) push registration is gone for good – it used
// the official KRÉTA app's Firebase project and a proprietary SDK. Local
// notifications live in update_notifier.dart. This stub keeps the old API so
// callers don't have to change.

import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/models/user.dart';

enum LastSeenCategory { grade, surprisegrade, absence, message, lesson }

enum NotificationRegistrationStatus {
  registered,
  tokenMismatch,
  notRegistered,
  noToken,
}

class NotificationHelper {
  static Future<void> initialize(User user, DatabaseProvider database) async {}

  static Future<void> subscribeIfNeeded(
      User user, DatabaseProvider database) async {}

  static Future<NotificationRegistrationStatus> checkStatus(
          User user, DatabaseProvider database) async =>
      NotificationRegistrationStatus.notRegistered;

  static Future<void> unsubscribe(User user, DatabaseProvider database) async {}
}
