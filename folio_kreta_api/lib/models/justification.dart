// Absence justification ("TMGI" case) in KRÉTA e-ügyintézés, as the official
// guardian app (hu.ekreta.guardian) sends it: POST /api/v1/ugy/kerelmek.

/// A KRÉTA dictionary item (TypeDto): kerelemtipusok, tmgiigazolastipusok.
class KretaType {
  String? id;
  String code;
  String name;

  /// Sent back unchanged, like the official app does.
  Map json;

  KretaType({this.id, required this.code, required this.name, required this.json});

  factory KretaType.fromJson(Map json) => KretaType(
        id: json["azonosito"]?.toString(),
        code: json["kod"] ?? "",
        name: json["nev"] ?? json["leiras"] ?? "",
        json: json,
      );
}

/// GET /api/v1/kreta/gyerekemadatok
class ChildData {
  String? familyName;
  String? givenName;
  String? educationId;
  String? className;

  ChildData({this.familyName, this.givenName, this.educationId, this.className});

  factory ChildData.fromJson(Map json) => ChildData(
        familyName: json["vezetekNev"],
        givenName: json["keresztNev"],
        educationId: json["oktatasiAzonosito"]?.toString(),
        className: json["osztaly"],
      );
}

/// One item of GET /api/v1/ugy/kerelmek (CaseDto).
class JustificationCase {
  String id;
  DateTime? start;
  DateTime? end;
  String typeName;
  String stateName;
  DateTime? sent;
  String reason;

  JustificationCase({
    required this.id,
    this.start,
    this.end,
    required this.typeName,
    required this.stateName,
    this.sent,
    required this.reason,
  });

  factory JustificationCase.fromJson(Map json) {
    String text(dynamic v) =>
        (v is String && v.trim().isNotEmpty) ? v.trim() : "–";
    Map? map(dynamic v) => v is Map ? v : null;
    final state = map(json["statusz"]);
    return JustificationCase(
      id: json["azonosito"]?.toString() ?? "",
      start: _parseDate(json["igazoltTavolletKezdeteDatum"]),
      end: _parseDate(json["igazoltTavolletVegeDatum"]),
      typeName: text(map(json["igazolasTipus"])?["nev"]),
      stateName: text(state?["nev"] ?? state?["leiras"]),
      sent: _parseDate(json["bekuldesDatum"], local: true),
      reason: text(json["indoklas"]),
    );
  }
}

DateTime? _parseDate(dynamic v, {bool local = false}) {
  if (v is! String) return null;
  final d = DateTime.tryParse(v);
  if (d == null) return null;
  return local ? d.toLocal() : DateTime(d.year, d.month, d.day);
}

String formatKretaDate(DateTime d) =>
    "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

bool isValidRange(DateTime? start, DateTime? end) {
  if (start == null || end == null) return false;
  return !DateTime(start.year, start.month, start.day)
      .isAfter(DateTime(end.year, end.month, end.day));
}

/// Body of POST /api/v1/ugy/kerelmek (TmgiCasePostDto).
Map<String, dynamic> buildTmgiBody({
  required ChildData child,
  required KretaType caseType,
  required KretaType justificationType,
  required DateTime start,
  required DateTime end,
  String reason = "",
}) =>
    {
      "tanuloCsaladiNev": child.familyName,
      "tanuloKeresztNev": child.givenName,
      "tanuloOktatasiAzonosito": child.educationId,
      "tanuloOsztaly": child.className,
      "tipus": caseType.json,
      "igazolasTipus": justificationType.json,
      "tipusKod": "TMGI",
      "igazoltTavolletKezdeteDatum": formatKretaDate(start),
      "igazoltTavolletVegeDatum": formatKretaDate(end),
      "indoklas": reason,
      "kerelemKotelezoDokumentumLista": [],
      "csatolmanyok": [],
    };
