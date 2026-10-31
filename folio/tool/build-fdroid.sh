#!/usr/bin/env bash
# F-Droid / IzzyOnDroid build: no Firebase anywhere in the dependency tree,
# no in-app updater (FLAVOR=fdroid), timed background checks for notifications.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -f pubspec_overrides.yaml
flutter pub get
flutter build apk --release --flavor fdroid --dart-define=FLAVOR=fdroid "$@"
# Proof for reviewers: the APK must not contain Firebase.
apk=build/app/outputs/flutter-apk/app-fdroid-release.apk
if unzip -l "$apk" | grep -qi firebase; then
  echo "HIBA: Firebase került az F-Droid APK-ba" >&2; exit 1
fi
echo "OK: $apk (Firebase nélkül)"
