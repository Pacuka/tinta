import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:folio/models/release.dart';
import 'package:path_provider/path_provider.dart';

/// Removes downloaded update APKs older than a day (the install happens right
/// after the download, so by then they are only taking up space). Covers the
/// update dialog's temp files and the ones older versions left in Downloads.
Future<void> cleanupOldUpdateApks({DateTime? now}) async {
  final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 1));
  final dirs = <Directory>[
    await getTemporaryDirectory(),
    if (Platform.isAndroid) Directory("/storage/self/primary/Download"),
  ];
  final ours = RegExp(r'^(folio_update_.*|folio-v.*)\.apk$');
  for (final dir in dirs) {
    try {
      await for (final f in dir.list(followLinks: false)) {
        if (f is! File || !ours.hasMatch(f.uri.pathSegments.last)) continue;
        if ((await f.lastModified()).isBefore(cutoff)) await f.delete();
      }
    } catch (_) {
      // No permission or the folder is gone: nothing to clean.
    }
  }
}

/// The installer of [release] that this phone can run (64 or 32 bit).
Future<ReleaseDownload?> phoneApkFor(Release release) async {
  try {
    final device = await DeviceInfoPlugin().androidInfo;
    return pickApk(release.downloads, abis: device.supportedAbis);
  } catch (_) {
    return pickApk(release.downloads);
  }
}
