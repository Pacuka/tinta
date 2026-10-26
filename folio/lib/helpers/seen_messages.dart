import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Messages opened in Tinta. KRÉTA has no documented "mark as read" call, so
/// we remember them locally to keep unread counts honest.
class SeenMessages {
  static Set<int>? _ids;

  static Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/seen_messages');

  static Future<Set<int>> load() async {
    if (_ids != null) return _ids!;
    try {
      final f = await _file();
      _ids = await f.exists()
          ? (await f.readAsString())
              .split(',')
              .map(int.tryParse)
              .whereType<int>()
              .toSet()
          : <int>{};
    } catch (_) {
      _ids = <int>{};
    }
    return _ids!;
  }

  static Future<void> add(int id) async {
    final ids = await load();
    if (!ids.add(id)) return;
    try {
      await (await _file()).writeAsString(ids.join(','));
    } catch (_) {}
  }
}
