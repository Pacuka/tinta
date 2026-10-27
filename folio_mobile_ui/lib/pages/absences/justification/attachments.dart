import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:folio_kreta_api/models/justification.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'justification.i18n.dart';

/// A picked file on its way to KRÉTA's temporary storage.
class PendingAttachment {
  final String name;
  final List<int> bytes;
  UploadedFile? uploaded;
  bool uploading = true;

  PendingAttachment(this.name, this.bytes);

  bool get failed => !uploading && uploaded == null;
}

/// Picks a file (camera / gallery / file) and uploads it right away.
/// Keeps the list of attachments for one section of a form.
class AttachmentController extends ChangeNotifier {
  final List<PendingAttachment> items = [];

  bool get uploading => items.any((a) => a.uploading);
  List<UploadedFile> get uploaded => [
        for (final a in items)
          if (a.uploaded != null) a.uploaded!
      ];

  Future<void> pickAndUpload(BuildContext context) async {
    final picked = await _pick(context);
    if (picked == null || !context.mounted) return;
    final item = PendingAttachment(picked.$1, picked.$2);
    items.add(item);
    notifyListeners();
    await _upload(context, item);
  }

  Future<void> retry(BuildContext context, PendingAttachment item) async {
    item.uploading = true;
    notifyListeners();
    await _upload(context, item);
  }

  void remove(PendingAttachment item) {
    items.remove(item);
    notifyListeners();
  }

  Future<void> _upload(BuildContext context, PendingAttachment item) async {
    final provider = Provider.of<CaseProvider>(context, listen: false);
    item.uploaded = await provider.upload(item.bytes, item.name);
    item.uploading = false;
    notifyListeners();
  }

  static Future<(String, List<int>)?> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: Text("source_camera".i18n),
            onTap: () => Navigator.pop(context, "camera"),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text("source_gallery".i18n),
            onTap: () => Navigator.pop(context, "gallery"),
          ),
          ListTile(
            leading: const Icon(Icons.description_rounded),
            title: Text("source_file".i18n),
            onTap: () => Navigator.pop(context, "file"),
          ),
        ]),
      ),
    );
    if (source == null) return null;
    if (source == "file") {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["pdf", "jpg", "jpeg", "png", "heic"],
        withData: true,
      );
      final f = res?.files.single;
      if (f == null || f.bytes == null) return null;
      return (f.name, f.bytes!.toList());
    }
    final image = await ImagePicker().pickImage(
      source: source == "camera" ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (image == null) return null;
    return (image.name, await image.readAsBytes());
  }
}

/// One attachment section ("Kötelezően csatolandó" / "Egyéb csatolt").
class AttachmentSection extends StatelessWidget {
  const AttachmentSection({
    super.key,
    required this.title,
    required this.controller,
    this.maxItems,
    this.enabled = true,
  });

  final String title;
  final AttachmentController controller;
  final int? maxItems;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final full = maxItems != null && controller.items.length >= maxItems!;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.8))),
          const SizedBox(height: 6),
          for (final a in controller.items)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: a.uploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(
                        a.failed
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_rounded,
                        color: a.failed ? scheme.error : scheme.secondary),
                title:
                    Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: a.failed ? Text("upload_failed".i18n) : null,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (a.failed)
                    IconButton(
                      tooltip: "retry".i18n,
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed:
                          enabled ? () => controller.retry(context, a) : null,
                    ),
                  IconButton(
                    tooltip: "delete".i18n,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: enabled && !a.uploading
                        ? () => _confirmRemove(context, a)
                        : null,
                  ),
                ]),
              ),
            ),
          if (!full)
            TextButton.icon(
              onPressed:
                  enabled ? () => controller.pickAndUpload(context) : null,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text("attach_new".i18n),
            ),
        ]);
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context, PendingAttachment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("delete_attachment_q".i18n),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("cancel".i18n)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("delete".i18n)),
        ],
      ),
    );
    if (ok == true) controller.remove(a);
  }
}
