// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';

import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/attachment.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// A file name that can't leave its folder or clash with special names.
@visibleForTesting
String safeAttachmentName(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f]'), '_')
      .replaceAll(RegExp(r'^\.+'), '')
      .trim();
  return cleaned.isEmpty ? "csatolmany" : cleaned;
}

/// Downloaded attachments live in the app's private cache (not the shared
/// Downloads folder, where other apps could read them), one folder per
/// attachment id, so two files with the same name never get mixed up.
Future<String> _cachedFile(
  String key,
  String name, {
  required Future<dynamic> Function() fetch,
  bool overwrite = false,
}) async {
  final dir = Directory("${(await getTemporaryDirectory()).path}/attachments/"
      "${safeAttachmentName(key)}");
  final file = File("${dir.path}/${safeAttachmentName(name)}");
  if (!overwrite && await file.exists() && await file.length() > 0) {
    return file.path;
  }
  final data = await fetch();
  // A failed download is not cached, so the next view tries again.
  if (data is! Uint8List || data.isEmpty) return "";
  try {
    await dir.create(recursive: true);
    await file.writeAsBytes(data, flush: true);
    return file.path;
  } catch (_) {
    return "";
  }
}

Future<bool> _openFile(String path) async {
  if (path.isEmpty) return false;
  final result = await OpenFilex.open(path);
  return result.type == ResultType.done;
}

extension AttachmentHelper on Attachment {
  Future<String> download(BuildContext context, {bool overwrite = false}) {
    final kreta = Provider.of<KretaClient>(context, listen: false);
    return _cachedFile("msg-$id", name,
        overwrite: overwrite,
        fetch: () => kreta.getAPI(downloadUrl, rawResponse: true));
  }

  Future<bool> open(BuildContext context) async =>
      _openFile(await download(context));
}

extension HomeworkAttachmentHelper on HomeworkAttachment {
  Future<String> download(BuildContext context, {bool overwrite = false}) {
    final kreta = Provider.of<KretaClient>(context, listen: false);
    final url = downloadUrl(
        Provider.of<UserProvider>(context, listen: false).instituteCode ?? "");
    return _cachedFile("hw-$id", name,
        overwrite: overwrite,
        fetch: () => kreta.getAPI(url, rawResponse: true));
  }

  Future<bool> open(BuildContext context) async =>
      _openFile(await download(context));
}
