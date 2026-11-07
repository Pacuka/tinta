import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:folio/api/client.dart';
import 'package:folio/helpers/storage_helper.dart';
import 'package:folio/models/release.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum UpdateState { none, preparing, downloading, installing }

typedef UpdateCallback = Function(double progress, UpdateState state);

/// Removes downloaded update APKs older than a day (the install happens right
/// after the download, so by then they are only taking up space). Covers the
/// update dialog's temp files and the old Downloads-folder ones.
Future<void> cleanupOldUpdateApks({DateTime? now}) async {
  final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 1));
  final dirs = <Directory>[
    await getTemporaryDirectory(),
    if (Platform.isAndroid) Directory(await StorageHelper.downloadsPath()),
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

extension UpdateHelper on Release {
  Future<void> install({UpdateCallback? updateCallback}) async {
    updateCallback!(-1, UpdateState.preparing);

    String downloads = await StorageHelper.downloadsPath();
    File apk = File("$downloads/folio-v$version.apk");

    if (!await apk.exists()) {
      updateCallback(-1, UpdateState.downloading);

      var bytes = await download(updateCallback: updateCallback);
      if (!await StorageHelper.write(apk.path, bytes)) {
        throw "failed to write apk: permission denied";
      }
    }

    updateCallback(-1, UpdateState.installing);

    var installPerms =
        (await Permission.manageExternalStorage.request().isGranted &&
            await Permission.requestInstallPackages.request().isGranted);
    if (installPerms) {
      var result = await OpenFilex.open(apk.path);

      if (result.type != ResultType.done) {
        // ignore: avoid_print
        print("ERROR: installUpdate.openFile: ${result.message}");
        throw result.message;
      }
    }

    updateCallback(-1, UpdateState.none);
  }

  Future<Uint8List> download({UpdateCallback? updateCallback}) async {
    final device = await DeviceInfoPlugin().androidInfo;
    final apk = pickApk(downloads, abis: device.supportedAbis);
    if (apk == null) throw "No Android APK in this release";
    var response = await FilcAPI.downloadRelease(apk);

    List<List<int>> chunks = [];
    int downloaded = 0;

    var completer = Completer<Uint8List>();

    response?.stream.listen((List<int> chunk) {
      updateCallback!(
          downloaded / (response.contentLength ?? 0), UpdateState.downloading);

      chunks.add(chunk);
      downloaded += chunk.length;
    }, onDone: () {
      // Save the file
      final Uint8List bytes = Uint8List(response.contentLength ?? 0);
      int offset = 0;
      for (List<int> chunk in chunks) {
        bytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      completer.complete(bytes);
    });

    return completer.future;
  }
}
