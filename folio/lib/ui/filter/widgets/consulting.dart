import 'package:folio/ui/date_widget.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_mobile_ui/pages/consulting/consulting_tile.dart';

/// Own consultation bookings that haven't ended yet.
List<DateWidget> getWidgets(List<ConsultingHour> hours) {
  final now = DateTime.now();
  final items = <DateWidget>[];
  for (final hour in hours) {
    final slot = hour.myBooking;
    if (slot == null || !slot.end.isAfter(now)) continue;
    items.add(DateWidget(
      key: "consulting-${slot.id}",
      date: slot.start,
      widget: ConsultingTile(hour),
    ));
  }
  return items;
}
