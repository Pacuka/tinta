import 'package:flutter/material.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_mobile_ui/common/round_border_icon.dart';
import 'package:folio_mobile_ui/common/type_tag.dart';
import 'package:folio_mobile_ui/pages/consulting/consulting_sheet.dart';
import 'package:intl/intl.dart';

/// Home feed item for an own consultation booking (looks like ExamTile).
class ConsultingTile extends StatelessWidget {
  const ConsultingTile(this.hour, {super.key});

  final ConsultingHour hour;

  @override
  Widget build(BuildContext context) {
    final slot = hour.myBooking!;
    final hm = DateFormat("HH:mm");
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.only(left: 8.0, right: 10.0),
          onTap: () => showConsultingSheet(context, hour),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          leading: const RoundBorderIcon(
            icon: Icon(Icons.event_available_rounded, size: 24.0),
            padding: 6.0,
            width: 1.0,
          ),
          title: Text(
            hour.teacherName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            "${hm.format(slot.start)}–${hm.format(slot.end)}"
            "${hour.room.isNotEmpty ? " · ${hour.room}" : ""}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0),
          ),
          trailing: const TypeTag("Fogadóóra"),
          minLeadingWidth: 0,
        ),
      ),
    );
  }
}
