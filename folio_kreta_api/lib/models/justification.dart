// Absence justification ("TMGI" case) in KRÉTA e-ügyintézés, as the official
// guardian app (hu.ekreta.guardian) sends it: POST /api/v1/ugy/kerelmek.

/// A KRÉTA dictionary item (TypeDto): kerelemtipusok, tmgiigazolastipusok.
class KretaType {
  String? id;
  String code;
  String name;

  /// Sent back unchanged, like the official app does.
  Map json;

  KretaType(
      {this.id, required this.code, required this.name, required this.json});

  @override
  bool operator ==(Object other) =>
      other is KretaType && other.code == code && other.id == id;

  @override
  int get hashCode => Object.hash(code, id);

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

  ChildData(
      {this.familyName, this.givenName, this.educationId, this.className});

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
  UploadedFile? mandatory,
  List<UploadedFile> others = const [],
}) {
  final docTypeId = mandatoryDocTypeId(justificationType.code);
  return {
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
    "kerelemKotelezoDokumentumLista": [
      if (mandatory != null && docTypeId != null)
        {
          "fajlNev": mandatory.name,
          "fajl": {"ideiglenesFajlAzonosito": mandatory.tempId},
          "tipus": {
            "azonosito": docTypeId.toString(),
            "rovidNev": justificationType.json["rovidNev"],
            "nev": justificationType.json["nev"],
            "leiras": justificationType.json["leiras"],
          },
        }
    ],
    "csatolmanyok": [for (final f in others) _otherAttachment(f)],
  };
}

Map<String, dynamic> _otherAttachment(UploadedFile f) => {
      "fajlNev": f.name,
      "fajl": {"ideiglenesFajlAzonosito": f.tempId},
    };

/// Document type the official app attaches as mandatory, per justification
/// type (hu.ekreta.guardian TmgiCaseType.TmgiType.codeToUpload).
int? mandatoryDocTypeId(String kod) => const {
      "ORVOSI": 36,
      "HIVATALOS_TAVOLLET": 39,
      "SZOLGALTATOI": 40,
      "KIKERO": 41,
    }[kod];

/// A file already uploaded to KRÉTA's temporary storage (ideiglenesfajlok).
class UploadedFile {
  final String name;
  final String tempId;
  const UploadedFile({required this.name, required this.tempId});
}

UploadedFile? parseTempFile(dynamic json, String name) {
  if (json is! Map) return null;
  final id = json["fajlAzonosito"] ?? json["fajlId"];
  if (id == null || id.toString().isEmpty) return null;
  return UploadedFile(name: name, tempId: id.toString());
}

bool canSubmit({
  required bool rangeOk,
  required KretaType? type,
  required bool hasMandatory,
  required bool uploading,
}) {
  if (!rangeOk || type == null || uploading) return false;
  return mandatoryDocTypeId(type.code) == null || hasMandatory;
}

String stateLabel(String? kod, String? fallback) {
  if (kod != null && kod.startsWith("HIANYPOTLAS")) {
    return "Hiánypótlás szükséges";
  }
  const labels = {
    "UJ": "Feldolgozásra vár",
    "FOLYAMATBAN": "Folyamatban",
    "ELFOGADVA": "Elfogadva",
    "ELFOGADVA_MODOSITASSAL": "Elfogadva módosítással",
    "ELUTASITVA": "Elutasítva",
    "LEZART": "Lezárva",
  };
  final l = labels[kod];
  if (l != null) return l;
  return (fallback != null && fallback.trim().isNotEmpty) ? fallback : "–";
}

String _text(dynamic v) =>
    (v is String && v.trim().isNotEmpty) ? v.trim() : "–";
Map? _map(dynamic v) => v is Map ? v : null;
List<Map> _maps(dynamic v) => v is List ? v.whereType<Map>().toList() : [];

class CaseDocument {
  final String name;
  final String? id;
  const CaseDocument(this.name, this.id);

  factory CaseDocument.fromJson(Map json) =>
      CaseDocument(_text(json["fajlNev"]), json["azonosito"]?.toString());
}

class Decision {
  final String? code;
  final String label;
  final DateTime? date;
  final String text;
  final String reason;
  final int? signerId;
  final String? filedId;
  final DateTime? start;
  final DateTime? end;

  const Decision({
    this.code,
    required this.label,
    this.date,
    required this.text,
    required this.reason,
    this.signerId,
    this.filedId,
    this.start,
    this.end,
  });

  factory Decision.fromJson(Map json) {
    final d = _map(json["dontes"]);
    final signer = json["alairoKretaAzonosito"];
    return Decision(
      code: d?["kod"],
      label: _text(d?["nev"] ?? d?["leiras"]),
      date: _parseDate(json["hatarozatDatum"], local: true),
      text: _text(json["dontesSzovege"]),
      reason: _text(json["indoklas"]),
      signerId: signer is int ? signer : int.tryParse("${signer ?? ""}"),
      filedId: _map(json["iktatottHatarozat"])?["azonosito"]?.toString(),
      start: _parseDate(json["igazoltTavolletKezdeteDatum"]),
      end: _parseDate(json["igazoltTavolletVegeDatum"]),
    );
  }
}

/// GET /api/v1/ugy/kerelmek/{id} (CaseDto) – everything the details page shows.
class CaseDetail {
  final JustificationCase summary;
  final String? stateCode;
  final String handlerName;
  final String studentName;
  final String educationId;
  final String? filedId;
  final List<CaseDocument> mandatoryDocs;
  final List<CaseDocument> otherDocs;
  final List<Decision> decisions;
  final Map raw;

  const CaseDetail({
    required this.summary,
    this.stateCode,
    required this.handlerName,
    required this.studentName,
    required this.educationId,
    this.filedId,
    required this.mandatoryDocs,
    required this.otherDocs,
    required this.decisions,
    required this.raw,
  });

  bool get needsRectification =>
      (stateCode?.startsWith("HIANYPOTLAS") ?? false) ||
      decisions.any((d) => d.code?.startsWith("HIANYPOTLAS") ?? false);

  factory CaseDetail.fromJson(Map json) {
    final names = [json["tanuloCsaladiNev"], json["tanuloKeresztNev"]]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty);
    return CaseDetail(
      summary: JustificationCase.fromJson(json),
      stateCode: _map(json["statusz"])?["kod"],
      handlerName: _text(_map(json["ugyintezo"])?["nev"]),
      studentName: names.isEmpty ? "–" : names.join(" "),
      educationId: _text(json["tanuloOktatasiAzonosito"]?.toString()),
      filedId: _map(json["iktatottKerelem"])?["azonosito"]?.toString(),
      mandatoryDocs: _maps(json["kerelemKotelezoDokumentumLista"])
          .map(CaseDocument.fromJson)
          .toList(),
      otherDocs:
          _maps(json["csatolmanyok"]).map(CaseDocument.fromJson).toList(),
      decisions: _maps(json["hatarozatLista"]).map(Decision.fromJson).toList(),
      raw: json,
    );
  }
}

/// Body of POST /api/v1/ugy/kerelmek/{ugyId} (RectificationPostDto).
Map<String, dynamic> buildRectificationBody(
        CaseDetail c, List<UploadedFile> files) =>
    {
      "azonosito": c.raw["azonosito"]?.toString(),
      "tipus": c.raw["tipus"],
      "tipusKod": c.raw["tipusKod"],
      "csatolmanyok": [for (final f in files) _otherAttachment(f)],
      "statusz": c.raw["statusz"],
    };

bool canSubmitRectification(List<UploadedFile> files, bool uploading) =>
    files.isNotEmpty && !uploading;
