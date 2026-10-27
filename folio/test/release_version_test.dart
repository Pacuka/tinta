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

  group('pickUpdates', () {
    Release r(String tag, {bool pre = false}) => Release.fromJson(
        {"tag_name": tag, "prerelease": pre, "assets": []});

    test('stable newer than current is the update', () {
      final (stable, preview) =
          pickUpdates([r("v1.2.0"), r("v1.3.0")], Version.fromString("1.2.0"));
      expect(stable?.tag, "v1.3.0");
      expect(preview, isNull);
    });

    test('a newer pre-release is only a preview, the stable still counts', () {
      final (stable, preview) = pickUpdates(
          [r("v1.4.0", pre: true), r("v1.3.0"), r("v1.2.0")],
          Version.fromString("1.2.0"));
      expect(stable?.tag, "v1.3.0");
      expect(preview?.tag, "v1.4.0");
    });

    test('a pre-release older than the stable update is ignored', () {
      final (stable, preview) = pickUpdates(
          [r("v1.3.0"), r("v1.2.5", pre: true)], Version.fromString("1.2.0"));
      expect(stable?.tag, "v1.3.0");
      expect(preview, isNull);
    });

    test('nothing newer', () {
      final (stable, preview) = pickUpdates(
          [r("v1.3.0", pre: true), r("v1.2.0")], Version.fromString("1.3.0"));
      expect(stable, isNull);
      expect(preview, isNull);
    });
  });
}
