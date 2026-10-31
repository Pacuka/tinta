#!/usr/bin/env bash
# Firebase build (GitHub releases): same app, with push support swapped in.
# Needs tool/push.json (git-ignored) with the Firebase project KRÉTA is
# allowed to send to; without it push stays off and the app works as usual.
set -euo pipefail
cd "$(dirname "$0")/.."
# pubspec_overrides.yaml replaces pubspec.yaml's whole dependency_overrides
# section, so copy that section first, then add the Firebase push package.
{
  awk '/^dependency_overrides:/{f=1;print;next} f&&/^[^ #]/{f=0} f' pubspec.yaml
  printf '  tinta_push:\n    path: ../tinta_push_firebase\n'
} > pubspec_overrides.yaml
trap 'rm -f pubspec_overrides.yaml; flutter pub get >/dev/null' EXIT
flutter pub get
defines=()
[ -f tool/push.json ] && defines+=(--dart-define-from-file=tool/push.json)
flutter build apk --release --flavor github "${defines[@]}" "$@"
echo "OK: build/app/outputs/flutter-apk/app-github-release.apk (Firebase-zel)"
