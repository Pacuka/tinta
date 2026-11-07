import 'dart:io';

import 'package:folio/helpers/share_helper.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen picture. The buttons float above it: a solid app bar would
/// stay as a band across a zoomed image, because PhotoView doesn't clip.
class ImageView extends StatelessWidget {
  const ImageView(this.path, {super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: PhotoView(
              imageProvider: FileImage(File(path)),
              maxScale: 4.0,
              minScale: PhotoViewComputedScale.contained,
              backgroundDecoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FloatingButton(child: const BackButton(color: Colors.white)),
                  _FloatingButton(
                    child: IconButton(
                      onPressed: () => ShareHelper.shareFile(path),
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.white),
                      splashRadius: 24.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  const _FloatingButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
