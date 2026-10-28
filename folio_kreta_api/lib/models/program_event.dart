/// School programmes a guardian has to allow: LÉP (Lázár Ervin Program,
/// sajat Lep/Eloadasok) and NÉP (Nep/Programok).
enum ProgramKind { lep, nep }

class ProgramEvent {
  ProgramEvent({
    required this.kind,
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.organizer = "",
    this.place = "",
    this.appeared = false,
    this.permitted,
  });

  final ProgramKind kind;

  /// LÉP: Uid (sent back as EloadasId), NÉP: Id.
  final int id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String organizer;
  final String place;

  /// Megjelent: the student was there.
  final bool appeared;

  /// GondviseloElfogadas: null = no decision yet.
  final bool? permitted;

  static DateTime _time(Object? v) => DateTime.parse(v as String).toLocal();

  static String _str(Object? v) => v is String ? v.trim() : "";

  /// null if the entry is unusable (no id or no times).
  static ProgramEvent? fromJson(ProgramKind kind, Map json) {
    try {
      final rawId = kind == ProgramKind.lep ? json["Uid"] : json["Id"];
      final id = rawId is int ? rawId : int.parse("$rawId");
      final lep = kind == ProgramKind.lep;
      return ProgramEvent(
        kind: kind,
        id: id,
        title: _str(lep ? json["EloadasNev"] : json["ProgramNev"]),
        start: _time(lep ? json["EloadasKezdete"] : json["Kezdete"]),
        end: _time(lep ? json["EloadasVege"] : json["Vege"]),
        organizer: _str(json["SzervezetNev"]),
        place: _str(json["Helyszin"]),
        appeared: json["Megjelent"] == true,
        permitted: json["GondviseloElfogadas"] is bool
            ? json["GondviseloElfogadas"] as bool
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  static List<ProgramEvent> listFromJson(ProgramKind kind, List json) =>
      json.whereType<Map>().map((e) => fromJson(kind, e)).nonNulls.toList();

  Map toCacheJson() => {
        "kind": kind.name,
        if (kind == ProgramKind.lep) ...{
          "Uid": "$id",
          "EloadasNev": title,
          "EloadasKezdete": start.toUtc().toIso8601String(),
          "EloadasVege": end.toUtc().toIso8601String(),
        } else ...{
          "Id": id,
          "ProgramNev": title,
          "Kezdete": start.toUtc().toIso8601String(),
          "Vege": end.toUtc().toIso8601String(),
        },
        "SzervezetNev": organizer,
        "Helyszin": place,
        "Megjelent": appeared,
        "GondviseloElfogadas": permitted,
      };

  static ProgramEvent? fromCacheJson(Map json) => fromJson(
      json["kind"] == "nep" ? ProgramKind.nep : ProgramKind.lep, json);

  /// Body of the GondviseloEngedelyezes POST.
  Map<String, Object> decisionBody(bool allow) => kind == ProgramKind.lep
      ? {"EloadasId": id, "Dontes": allow}
      : {"Id": id, "Dontes": allow};

  /// Like the official app: a decision is possible until a day before it
  /// starts.
  bool canDecide(DateTime now) =>
      now.isBefore(start.subtract(const Duration(days: 1)));

  ProgramEvent withDecision(bool allow) => ProgramEvent(
        kind: kind,
        id: id,
        title: title,
        start: start,
        end: end,
        organizer: organizer,
        place: place,
        appeared: appeared,
        permitted: allow,
      );
}

/// Rendszermodulok[] of TanuloAdatlap.Intezmeny: is [type] ("LEP", "NEP")
/// switched on for the school?
bool schoolModuleActive(Map? student, String type) {
  final modules = student?["Intezmeny"]?["Rendszermodulok"];
  if (modules is! List) return false;
  return modules
      .whereType<Map>()
      .any((m) => m["Tipus"] == type && m["IsAktiv"] == true);
}

/// Is the guardian called [name] the student's legal representative?
/// null when KRÉTA doesn't tell (then KRÉTA itself decides on submit).
bool? isLegalRepresentative(Map? student, String name) {
  final n = name.trim().toLowerCase();
  if (n.isEmpty) return null;
  final guardians = student?["Gondviselok"];
  if (guardians is! List) return null;
  for (final g in guardians.whereType<Map>()) {
    if ("${g["Nev"] ?? ""}".trim().toLowerCase() == n) {
      final v = g["IsTorvenyesKepviselo"];
      return v is bool ? v : null;
    }
  }
  return null;
}
