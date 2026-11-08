import 'package:flutter_test/flutter_test.dart';
import 'package:folio/api/providers/wear_provider.dart';
import 'package:folio/models/release.dart';

void main() {
  ReleaseDownload d(String tag, String name) => ReleaseDownload(
      url: "https://github.com/Pacuka/tinta/releases/download/$tag/$name",
      size: 1);
  Release r(String tag, List<String> files, {bool pre = false}) => Release(
      tag: tag,
      author: "",
      body: "",
      downloads: [for (final f in files) d(tag, f)],
      prerelease: pre,
      version: Version.fromString(tag));

  test('pickWearApk finds the watch installer only', () {
    final files = [
      d("v1.6.2", "Tinta.ipa"),
      d("v1.6.2", "Tinta-1.6.2-arm64.apk"),
      d("v1.6.2", "tinta-wear-1.6.2.apk"),
    ];
    expect(pickWearApk(files)?.url, endsWith("tinta-wear-1.6.2.apk"));
    expect(pickWearApk(files.take(2).toList()), isNull);
  });

  group('pickWearUpdate', () {
    final releases = [
      r("v1.7.0", ["tinta-wear-1.7.0.apk"], pre: true),
      r("v1.6.3", ["Tinta-1.6.3-arm64.apk"]),
      r("v1.6.2", ["Tinta-1.6.2-arm64.apk", "tinta-wear-1.6.2.apk"]),
      r("v1.6.1", ["tinta-wear-1.6.1.apk"]),
    ];

    test('newest stable release with a watch file, newer than the watch', () {
      expect(pickWearUpdate(releases, "1.6.1")?.tag, "v1.6.2");
    });

    test('nothing when the watch is up to date or newer', () {
      expect(pickWearUpdate(releases, "1.6.2"), isNull);
      expect(pickWearUpdate(releases, "1.8.0"), isNull);
    });

    test('nothing while the watch version is unknown', () {
      expect(pickWearUpdate(releases, null), isNull);
      expect(pickWearUpdate(releases, ""), isNull);
    });
  });

  test('parseWatchVersion reads the name, ignores junk', () {
    expect(parseWatchVersion('{"name":"1.6.1","code":10}'), "1.6.1");
    expect(parseWatchVersion('nem json'), isNull);
    expect(parseWatchVersion('{"code":10}'), isNull);
  });
}
