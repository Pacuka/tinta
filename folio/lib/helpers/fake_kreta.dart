import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:path_provider/path_provider.dart';

/// Debug builds only: route every KRÉTA request to the fake KRÉTA server on
/// the developer's computer (reached from the phone via
/// `adb reverse tcp:8765 tcp:8765`), so test messages and requests never reach
/// a school. Only in debug builds or test builds made with
/// `--dart-define=KAMU_KRETA=true`; normal release builds ignore it.
class FakeKreta {
  static const host = 'http://127.0.0.1:8765';

  static const available =
      kDebugMode || bool.fromEnvironment('KAMU_KRETA');

  static bool get enabled => BaseKreta.fakeHost != null;

  static Future<File> _flag() async =>
      File('${(await getApplicationSupportDirectory()).path}/fake_kreta');

  /// Called at startup.
  static Future<void> load() async {
    if (!available) return;
    try {
      if (await (await _flag()).exists()) BaseKreta.fakeHost = host;
    } catch (_) {}
  }

  static Future<void> setEnabled(bool on) async {
    if (!available) return;
    BaseKreta.fakeHost = on ? host : null;
    final f = await _flag();
    try {
      on ? await f.writeAsString('1') : (await f.exists() ? await f.delete() : null);
    } catch (_) {}
  }
}
