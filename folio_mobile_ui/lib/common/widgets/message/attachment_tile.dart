import 'package:folio_kreta_api/models/attachment.dart';
import 'package:folio/helpers/attachment_helper.dart';
import 'package:folio_mobile_ui/common/widgets/message/attachment_image.dart';
import 'package:folio_mobile_ui/common/widgets/message/image_view.dart';
import 'package:flutter/material.dart';

class AttachmentTile extends StatelessWidget {
  const AttachmentTile(this.attachment, {super.key});

  final Attachment attachment;

  Widget buildImage(BuildContext context) {
    return AttachmentImage(
      name: attachment.name,
      download: () => attachment.download(context),
      onOpen: (path) {
        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (context) => ImageView(path),
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) return buildImage(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          attachment.open(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            const Icon(Icons.attach_file_rounded),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(attachment.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
