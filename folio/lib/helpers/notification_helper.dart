// Tinta: the old Firebase (FCM) push registration is gone for good – it used
// the official KRÉTA app's Firebase project and a proprietary SDK. Local
// notifications live in update_notifier.dart; only this enum is still used.

enum LastSeenCategory { grade, surprisegrade, absence, message, lesson }
