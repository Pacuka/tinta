/// Homeroom teacher (Osztályfőnök) contact from
/// felhasznalok/Alkalmazottak/Tanarok/Osztalyfonokok.
class ClassMaster {
  ClassMaster({
    required this.uid,
    required this.name,
    this.emails = const [],
    this.phones = const [],
  });

  final String uid;
  final String name;
  final List<String> emails;
  final List<String> phones;

  static List<String> _values(Object? list, String key) => list is List
      ? list
          .whereType<Map>()
          .map((e) => "${e[key] ?? ""}".trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
      : const [];

  static ClassMaster? fromJson(Map json) {
    final employee = json["Tanar"] is Map ? json["Tanar"]["Alkalmazott"] : null;
    if (employee is! Map) return null;
    final name = "${employee["Nev"] ?? ""}".trim();
    if (name.isEmpty) return null;
    return ClassMaster(
      uid: "${json["Uid"] ?? ""}",
      name: name,
      emails: _values(employee["Emailek"], "Email"),
      phones: _values(employee["Telefonok"], "Telefonszam"),
    );
  }

  Map toJson() => {
        "Uid": uid,
        "Tanar": {
          "Alkalmazott": {
            "Nev": name,
            "Emailek": emails.map((e) => {"Email": e}).toList(),
            "Telefonok": phones.map((p) => {"Telefonszam": p}).toList(),
          }
        },
      };
}

/// OsztalyFonok.Uid of the active groups (OsztalyCsoportok), ";"-joined
/// like the official app sends them; empty if there is none.
String classMasterUids(List groups) => groups
    .whereType<Map>()
    .where((g) => g["IsAktiv"] != false)
    .map((g) => g["OsztalyFonok"] is Map ? "${g["OsztalyFonok"]["Uid"] ?? ""}" : "")
    .where((u) => u.isNotEmpty)
    .toSet()
    .join(";");
