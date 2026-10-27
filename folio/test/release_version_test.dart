import 'package:flutter_test/flutter_test.dart';
import 'package:folio/models/release.dart';

void main() {
  test('GitHub tags with a leading v parse as the real version', () {
    final v = Version.fromString("v1.2.0");
    expect([v.major, v.minor, v.patch], [1, 2, 0]);
    expect(v.compareTo(Version.fromString("1.1.1")), 1);
    final upper = Version.fromString("V1.1.2");
    expect([upper.major, upper.minor, upper.patch], [1, 1, 2]);
  });

  test('updater picks the Android APK, preferring arm64', () {
    ReleaseDownload d(String name) => ReleaseDownload(
        url: "https://github.com/Pacuka/tinta/releases/download/v1.2.0/$name",
        size: 1);
    expect(
        pickApk([d("Tinta.ipa"), d("Tinta-1.2.0-armeabi.apk"),
                d("Tinta-1.2.0-arm64.apk")])
            ?.url,
        endsWith("arm64.apk"));
    expect(pickApk([d("Tinta.ipa"), d("Tinta-1.2.0-armeabi.apk")])?.url,
        endsWith("armeabi.apk"));
    expect(pickApk([d("Tinta.ipa")]), isNull);
  });
}
