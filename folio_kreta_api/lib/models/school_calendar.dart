/// "Tanév rendje": one KRÉTA calendar entry per school-year day
/// (sajat/Intezmenyek/TanevRendjeElemek).
class SchoolCalendarDay {
  SchoolCalendarDay({
    required this.date,
    required this.type,
    this.typeDesc = "",
    this.followsDay,
    this.followsDayDesc = "",
    this.weekType = "",
    this.weekTypeDesc = "",
  });

  /// Local date, midnight.
  final DateTime date;

  /// Naptipus.Nev, e.g. "oszi_szunet", "tanitasi_nap".
  final String type;

  /// Naptipus.Leiras, e.g. "Őszi szünet".
  final String typeDesc;

  /// ElteroOrarendSzerintiTanitasiNap.Nev ("Hetfo" ...), null if none.
  final String? followsDay;
  final String followsDayDesc;

  /// OrarendiNapHetirendje.Nev / Leiras ("MindegyikHet", "A hét" ...).
  final String weekType;
  final String weekTypeDesc;

  static String _nev(dynamic v) =>
      v is Map && v["Nev"] is String ? v["Nev"] as String : "";
  static String _leiras(dynamic v) =>
      v is Map && v["Leiras"] is String ? v["Leiras"] as String : "";

  factory SchoolCalendarDay.fromJson(Map json) {
    final d = DateTime.parse(json["Datum"] as String).toLocal();
    final follows = _nev(json["ElteroOrarendSzerintiTanitasiNap"]);
    return SchoolCalendarDay(
      date: DateTime(d.year, d.month, d.day),
      type: _nev(json["Naptipus"]),
      typeDesc: _leiras(json["Naptipus"]),
      followsDay: follows.isEmpty || follows == "na" ? null : follows,
      followsDayDesc: _leiras(json["ElteroOrarendSzerintiTanitasiNap"]),
      weekType: _nev(json["OrarendiNapHetirendje"]),
      weekTypeDesc: _leiras(json["OrarendiNapHetirendje"]),
    );
  }

  Map toCacheJson() => {
        "Datum": DateTime(date.year, date.month, date.day).toIso8601String(),
        "Naptipus": {"Nev": type, "Leiras": typeDesc},
        if (followsDay != null)
          "ElteroOrarendSzerintiTanitasiNap": {
            "Nev": followsDay,
            "Leiras": followsDayDesc
          },
        "OrarendiNapHetirendje": {"Nev": weekType, "Leiras": weekTypeDesc},
      };

  static List<SchoolCalendarDay> listFromJson(List json) {
    final days = <SchoolCalendarDay>[];
    for (final e in json.whereType<Map>()) {
      try {
        days.add(SchoolCalendarDay.fromJson(e));
      } catch (_) {}
    }
    days.sort((a, b) => a.date.compareTo(b.date));
    return days;
  }
}

/// A school week from sajat/Intezmenyek/Hetirendek/Orarendi.
class SchoolWeek {
  SchoolWeek({
    required this.start,
    required this.end,
    required this.number,
    this.type = "",
    this.typeDesc = "",
  });

  final DateTime start;
  final DateTime end;

  /// HetSorszama: KRÉTA's own week number in the school year.
  final int number;
  final String type;
  final String typeDesc;

  /// "A hét" etc.; null for schools without A/B weeks.
  String? get label =>
      type != "MindegyikHet" && type.isNotEmpty && typeDesc.trim().isNotEmpty
          ? typeDesc.trim()
          : null;

  /// Short form for tight places: "A hét" -> "A", anything else as is.
  String? get shortLabel {
    final l = label;
    if (l == null) return null;
    final m = RegExp(r'^(\S{1,2})\s+hét$', caseSensitive: false).firstMatch(l);
    return m != null ? m.group(1) : l;
  }

  static DateTime _day(String s) {
    final d = DateTime.parse(s).toLocal();
    return DateTime(d.year, d.month, d.day);
  }

  factory SchoolWeek.fromJson(Map json) => SchoolWeek(
        start: _day(json["KezdoNapDatuma"] as String),
        end: _day(json["VegNapDatuma"] as String),
        number: (json["HetSorszama"] as num).toInt(),
        type: json["Tipus"] is Map ? json["Tipus"]["Nev"] ?? "" : "",
        typeDesc: json["Tipus"] is Map ? json["Tipus"]["Leiras"] ?? "" : "",
      );

  Map toCacheJson() => {
        "KezdoNapDatuma": start.toIso8601String(),
        "VegNapDatuma": end.toIso8601String(),
        "HetSorszama": number,
        "Tipus": {"Nev": type, "Leiras": typeDesc},
      };
}

/// Days with no lessons for the student.
const freeDayTypes = {
  "munkaszuneti_nap",
  "tanitas_nelkuli_munkanap",
  "szuloi_ertekezlet_tanitas_nelkul_",
  "fogadonap_tanitas_nelkuli_",
  "szabadnap_igazgatoi_hataskorben_",
  "tanitasi_szunet",
  "unnepnap",
  "teli_szunet",
  "tavaszi_szunet",
  "oszi_szunet",
};

/// Ordinary days that never get their own row.
const _plainTypes = {"tanitasi_nap", "Pihenonap", "na", ""};

/// Fallback names when KRÉTA sends no Leiras.
const _typeNames = {
  "munkaszuneti_nap": "Munkaszüneti nap",
  "tanitas_nelkuli_munkanap": "Tanítás nélküli munkanap",
  "szuloi_ertekezlet_tanitas_nelkul_": "Szülői értekezlet (tanítás nélkül)",
  "egesz_napos_kirandulas": "Egész napos kirándulás",
  "fogadonap_tanitas_nelkuli_": "Fogadónap (tanítás nélkül)",
  "szabadnap_igazgatoi_hataskorben_": "Igazgatói szünnap",
  "tanitasi_szunet": "Tanítási szünet",
  "roviditett_orakat_tartalmazo_tanitasi_nap": "Rövidített órás nap",
  "elso_tanitasi_nap": "Első tanítási nap",
  "utolso_tanitasi_nap": "Utolsó tanítási nap",
  "unnepnap": "Ünnepnap",
  "teli_szunet": "Téli szünet",
  "tavaszi_szunet": "Tavaszi szünet",
  "oszi_szunet": "Őszi szünet",
  "elso_felev_vege": "Első félév vége",
  "vizsganap": "Vizsganap",
  "utolso_tanitasi_nap_a_vegzos_evfolyamokon":
      "Utolsó tanítási nap a végzősöknek",
  "I_negyedev_vege": "I. negyedév vége",
  "III_negyedev_vege": "III. negyedév vége",
  "OsszefuggoSzakmaiGyakorlatiNap": "Szakmai gyakorlati nap",
  "RendkivuliTanitasiNap": "Rendkívüli tanítási nap",
  "Nyilt_nap": "Nyílt nap",
};

const _dayNames = {
  "Hetfo": "hétfői",
  "Kedd": "keddi",
  "Szerda": "szerdai",
  "Csutortok": "csütörtöki",
  "Pentek": "pénteki",
  "Szombat": "szombati",
  "Vasarnap": "vasárnapi",
};

/// One row of the "Tanév rendje" list: a single day or a merged range.
class SchoolCalendarItem {
  SchoolCalendarItem({
    required this.type,
    required this.title,
    required this.first,
    required this.last,
    this.note,
  });

  final String type;
  final String title;
  final DateTime first;
  final DateTime last;

  /// e.g. "hétfői órarend szerint".
  final String? note;

  bool get isFree => freeDayTypes.contains(type);
  bool get isRange => first != last;

  /// Days from [first] to [last], both included.
  int get length => last.difference(first).inDays + 1;
}

bool _weekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

/// "Őszi szünet (Nem órarendi nap) (Szerda)" -> "Őszi szünet".
String _clean(String s) => s
    .replaceAll(RegExp(r'\([^)]*\)'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

const _weekdays = {
  "Hetfo": 1,
  "Kedd": 2,
  "Szerda": 3,
  "Csutortok": 4,
  "Pentek": 5,
  "Szombat": 6,
  "Vasarnap": 7,
};

String _title(SchoolCalendarDay d) {
  final desc = _clean(d.typeDesc);
  if (desc.isNotEmpty) return desc;
  return _typeNames[d.type] ?? d.type.replaceAll("_", " ").trim();
}

/// Only the days worth showing, with neighbouring days of the same kind
/// merged into one range (a weekend in between doesn't break a range).
List<SchoolCalendarItem> buildSchoolCalendar(List<SchoolCalendarDay> days) {
  final items = <SchoolCalendarItem>[];
  final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));

  for (final d in sorted) {
    String? note;
    // KRÉTA names every day's own weekday here; only a different one matters.
    if (d.followsDay != null && _weekdays[d.followsDay] != d.date.weekday) {
      final name = _dayNames[d.followsDay];
      if (name != null) note = "$name órarend szerint";
    }

    final plain = _plainTypes.contains(d.type);
    // An ordinary school day only matters on a weekend or with another
    // day's timetable (e.g. a Saturday working day).
    if (plain && note == null && !(d.type == "tanitasi_nap" && _weekend(d.date))) {
      continue;
    }
    final title = plain ? "Tanítási nap" : _title(d);

    if (items.isNotEmpty && note == null) {
      final prev = items.last;
      final gap = d.date.difference(prev.last).inDays;
      var between = true;
      for (var i = 1; i < gap; i++) {
        if (!_weekend(prev.last.add(Duration(days: i)))) between = false;
      }
      if (prev.type == d.type && prev.title == title && prev.note == null &&
          gap >= 1 && between) {
        items[items.length - 1] = SchoolCalendarItem(
            type: prev.type, title: title, first: prev.first, last: d.date);
        continue;
      }
    }

    items.add(SchoolCalendarItem(
        type: d.type, title: title, first: d.date, last: d.date, note: note));
  }

  return _mergeBreaks(_extendBreaks(_mergeBreaks(items)));
}

/// A day off touching a break (e.g. Christmas inside "Téli szünet",
/// a holiday on the Sunday after "Őszi szünet") becomes part of it.
List<SchoolCalendarItem> _mergeBreaks(List<SchoolCalendarItem> items) {
  final out = <SchoolCalendarItem>[];
  for (final it in items) {
    if (out.isNotEmpty) {
      final prev = out.last;
      final isBreak = prev.type.contains("szunet") || it.type.contains("szunet");
      var touches = !it.first.isAfter(prev.last.add(const Duration(days: 1)));
      if (!touches) {
        touches = true;
        for (var d = prev.last.add(const Duration(days: 1));
            d.isBefore(it.first);
            d = d.add(const Duration(days: 1))) {
          if (!_weekend(d)) touches = false;
        }
      }
      if (prev.isFree && it.isFree && isBreak && touches) {
        final main = prev.type.contains("szunet") ? prev : it;
        out[out.length - 1] = SchoolCalendarItem(
          type: main.type,
          title: main.title,
          first: prev.first,
          last: it.last.isAfter(prev.last) ? it.last : prev.last,
        );
        continue;
      }
    }
    out.add(it);
  }
  return out;
}

List<SchoolCalendarItem> _extendBreaks(List<SchoolCalendarItem> input) {
  final items = [...input];
  // A break that ends on a Friday really lasts until Sunday, unless the
  // Saturday is a working day.
  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    if (!it.type.contains("szunet") || it.last.weekday != DateTime.friday) {
      continue;
    }
    final sat = it.last.add(const Duration(days: 1));
    final next = i + 1 < items.length ? items[i + 1] : null;
    if (next != null &&
        !next.isFree &&
        !next.first.isAfter(sat.add(const Duration(days: 1)))) {
      continue;
    }
    items[i] = SchoolCalendarItem(
        type: it.type,
        title: it.title,
        first: it.first,
        last: it.last.add(const Duration(days: 2)),
        note: it.note);
  }
  return items;
}

/// The free period going on [today], or the next one; null if none left.
SchoolCalendarItem? nextFreeItem(
    List<SchoolCalendarItem> items, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  for (final i in items) {
    if (i.isFree && !i.last.isBefore(t)) return i;
  }
  return null;
}
