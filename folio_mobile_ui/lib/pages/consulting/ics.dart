import 'dart:io';

import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

String _utc(DateTime d) {
  final u = d.toUtc();
  String two(int v) => v.toString().padLeft(2, "0");
  return "${u.year}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z";
}

/// RFC 5545 TEXT escaping.
String _text(String s) => s
    .replaceAll("\\", "\\\\")
    .replaceAll(";", "\\;")
    .replaceAll(",", "\\,")
    .replaceAll("\n", "\\n");

/// One calendar event for a booked consultation slot.
String buildIcs(ConsultingHour hour, ConsultingSlot slot) => [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Tinta//Fogadoora//HU",
      "BEGIN:VEVENT",
      "UID:${slot.id}@tinta",
      "DTSTAMP:${_utc(DateTime.now())}",
      "DTSTART:${_utc(slot.start)}",
      "DTEND:${_utc(slot.end)}",
      "SUMMARY:${_text("Fogadóóra – ${hour.teacherName}")}",
      if (hour.room.isNotEmpty) "LOCATION:${_text(hour.room)}",
      "END:VEVENT",
      "END:VCALENDAR",
      "",
    ].join("\r\n");

/// Hands the event to the phone's calendar app via the share sheet.
Future<void> shareIcs(ConsultingHour hour, ConsultingSlot slot) async {
  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/fogadoora.ics");
  await file.writeAsString(buildIcs(hour, slot));
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: "text/calendar")],
    subject: "Fogadóóra – ${hour.teacherName}",
  ));
}
