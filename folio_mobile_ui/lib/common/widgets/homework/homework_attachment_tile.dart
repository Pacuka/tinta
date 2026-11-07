import 'package:folio/helpers/attachment_helper.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_mobile_ui/common/custom_snack_bar.dart';
import 'package:folio_mobile_ui/common/widgets/message/attachment_image.dart';
import 'package:folio_mobile_ui/common/widgets/message/image_view.dart';

import 'package:folio_kreta_api/models/homework.dart';
import 'package:flutter/material.dart';

import 'homework_attachment_tile.i18n.dart';

class HomeworkAttachmentTile extends StatelessWidget {
  const HomeworkAttachmentTile(this.attachment, {super.key});

  final HomeworkAttachment attachment;

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
          attachment.open(context).then((value) {
            if (!value) {
              ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(
                context: context,
                content: Text("Failed to open attachment".i18n),
                backgroundColor: AppColors.of(context).red,
                duration: const Duration(seconds: 1),
              ));
            }
          });
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
