#!/usr/bin/env bash
# Builds every Android file of a release into ../tinta-<version>/:
# phone APKs, the watch APK, SHA256SUMS and the debug symbols (keep those).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
version="$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' "$root/folio/pubspec.yaml")"
watch="$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' "$root/folio_wear/pubspec.yaml")"
out="$root/../tinta-$version"

if [ "$version" != "$watch" ]; then
  echo "Eltérő verzió: telefon $version, óra $watch" >&2
  exit 1
fi

(cd "$root/folio" && flutter test)
(cd "$root/folio_wear" && flutter test)
(cd "$root/folio_wear/android" && JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk}" ./gradlew :app:testReleaseUnitTest -q)

mkdir -p "$out/debug-symbols"

(cd "$root/folio" && flutter build apk --release --flavor github --split-per-abi \
  --target-platform android-arm,android-arm64 \
  --obfuscate --split-debug-info="$out/debug-symbols")
for abi in arm64-v8a armeabi-v7a; do
  cp "$root/folio/build/app/outputs/flutter-apk/app-$abi-github-release.apk" \
    "$out/tinta-$version-$abi.apk"
done

# The Galaxy Watch7 runs 32-bit only, so the watch APK carries both.
(cd "$root/folio_wear" && flutter build apk --release \
  --target-platform android-arm,android-arm64)
cp "$root/folio_wear/build/app/outputs/flutter-apk/app-release.apk" \
  "$out/tinta-wear-$version.apk"

# One-ABI copies for the phone-to-watch update (half the size over
# Bluetooth). Separate builds, not --split-per-abi, so the version code
# stays the same as the universal file's.
for abi in armeabi-v7a:android-arm arm64-v8a:android-arm64; do
  (cd "$root/folio_wear" && flutter build apk --release \
    --target-platform "${abi#*:}")
  cp "$root/folio_wear/build/app/outputs/flutter-apk/app-release.apk" \
    "$out/tinta-wear-$version-${abi%%:*}.apk"
done

(cd "$out" && sha256sum tinta-*.apk > SHA256SUMS && cat SHA256SUMS)
