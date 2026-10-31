// Distribution flavor flag — set via --dart-define=FLAVOR=playstore
const String _kFlavor =
    String.fromEnvironment('FLAVOR', defaultValue: 'github');

/// true when built for Google Play Store — disables APK self-update
const bool kIsPlayStore = _kFlavor == 'playstore';

/// true for the F-Droid / IzzyOnDroid build (--dart-define=FLAVOR=fdroid):
/// the store handles updates, so the app never checks GitHub for them.
const bool kIsFdroid = _kFlavor == 'fdroid';
