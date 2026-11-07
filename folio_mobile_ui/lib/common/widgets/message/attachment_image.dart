import 'dart:io';

import 'package:flutter/material.dart';

import 'attachment_image.i18n.dart';

/// Inline picture of a KRÉTA attachment. [download] gives the local path, or
/// an empty one if the file couldn't be fetched; then a retry row is shown
/// instead of an empty box.
class AttachmentImage extends StatefulWidget {
  const AttachmentImage({
    super.key,
    required this.name,
    required this.download,
    required this.onOpen,
  });

  final String name;
  final Future<String> Function() download;
  final void Function(String path) onOpen;

  @override
  State<AttachmentImage> createState() => _AttachmentImageState();
}

class _AttachmentImageState extends State<AttachmentImage> {
  late Future<String> _file = widget.download();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _file,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary),
          ));
        }

        final path = snapshot.data ?? "";
        if (path.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () {
                setState(() {
                  _file = widget.download();
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  const Icon(Icons.broken_image_rounded),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text("download_failed".i18n,
                              style: const TextStyle(fontSize: 13.0)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Material(
              child: InkWell(
                onTap: () => widget.onOpen(path),
                borderRadius: BorderRadius.circular(12.0),
                child: Ink.image(
                  image: FileImage(File(path)),
                  height: 200.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
