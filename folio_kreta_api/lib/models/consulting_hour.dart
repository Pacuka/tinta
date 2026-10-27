// Teacher consultation hours ("fogadóórák") as the official student/guardian
// apps read them: GET ellenorzo/v3/sajat/Fogadoorak (ConsultingHourListDto).

enum ConsultingState { booked, noSignup, closed, full, open }

DateTime? _date(dynamic v) {
  if (v is! String) return null;
  return DateTime.tryParse(v)?.toLocal();
}

class ConsultingSlot {
  String id;
  DateTime start;
  DateTime end;

  /// IsJelentkeztem: booked by this account.
  bool mine;

  ConsultingSlot(
      {required this.id,
      required this.start,
      required this.end,
      this.mine = false});

  factory ConsultingSlot.fromJson(Map json) => ConsultingSlot(
        id: json["Uid"]?.toString() ?? "",
        start: _date(json["KezdoIdopont"]) ?? DateTime(0),
        end: _date(json["VegIdopont"]) ?? DateTime(0),
        mine: json["IsJelentkeztem"] == true,
      );

  Map<String, dynamic> toJson() => {
        "Uid": id,
        "KezdoIdopont": start.toUtc().toIso8601String(),
        "VegIdopont": end.toUtc().toIso8601String(),
        "IsJelentkeztem": mine,
      };
}

class ConsultingHour {
  String id;
  String teacherId;
  String teacherName;
  DateTime start;
  DateTime end;

  /// JelentkezesHatarido; null when KRÉTA gives none (or garbage).
  DateTime? deadline;
  bool signupEnabled;
  String room;
  List<ConsultingSlot> slots;

  ConsultingHour({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.start,
    required this.end,
    this.deadline,
    required this.signupEnabled,
    required this.room,
    required this.slots,
  });

  ConsultingSlot? get myBooking {
    for (final s in slots) {
      if (s.mine) return s;
    }
    return null;
  }

  /// KRÉTA has no "taken by others" flag: every listed slot that is not ours
  /// and hasn't started is offered; a race is reported by the booking call.
  List<ConsultingSlot> freeSlotsAt(DateTime now) =>
      slots.where((s) => !s.mine && s.start.isAfter(now)).toList();

  List<ConsultingSlot> get freeSlots => freeSlotsAt(DateTime.now());

  ConsultingState state(DateTime now) {
    if (myBooking != null) return ConsultingState.booked;
    if (!signupEnabled) return ConsultingState.noSignup;
    if ((deadline ?? end).isBefore(now)) return ConsultingState.closed;
    if (freeSlotsAt(now).isEmpty) return ConsultingState.full;
    return ConsultingState.open;
  }

  factory ConsultingHour.fromJson(Map json,
          {required String teacherId, required String teacherName}) =>
      ConsultingHour(
        id: json["Uid"]?.toString() ?? "",
        teacherId: teacherId,
        teacherName: teacherName,
        start: _date(json["KezdoIdopont"]) ?? DateTime(0),
        end: _date(json["VegIdopont"]) ?? DateTime(0),
        deadline: _date(json["JelentkezesHatarido"]),
        signupEnabled: json["IsJelentkezesFeatureEnabled"] == true,
        room: (json["Terem"] is Map ? json["Terem"]["Nev"]?.toString() : null) ??
            "",
        slots: (json["Idopontok"] is List ? json["Idopontok"] as List : const [])
            .whereType<Map>()
            .map(ConsultingSlot.fromJson)
            .toList(),
      );

  /// Flattens `List<ConsultingHourListDto>` (one entry per teacher), sorted by
  /// start time.
  static List<ConsultingHour> listFromJson(List json) {
    final out = <ConsultingHour>[];
    for (final t in json.whereType<Map>()) {
      final teacher = t["Tanar"] is Map ? t["Tanar"] as Map : const {};
      final hours = t["Fogadoorak"];
      if (hours is! List) continue;
      for (final h in hours.whereType<Map>()) {
        out.add(ConsultingHour.fromJson(h,
            teacherId: teacher["Uid"]?.toString() ?? "",
            teacherName: teacher["Nev"]?.toString() ?? ""));
      }
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  Map<String, dynamic> toCacheJson() => {
        "Uid": id,
        "TanarUid": teacherId,
        "TanarNev": teacherName,
        "KezdoIdopont": start.toUtc().toIso8601String(),
        "VegIdopont": end.toUtc().toIso8601String(),
        "JelentkezesHatarido": deadline?.toUtc().toIso8601String(),
        "IsJelentkezesFeatureEnabled": signupEnabled,
        "Terem": {"Nev": room},
        "Idopontok": slots.map((s) => s.toJson()).toList(),
      };

  factory ConsultingHour.fromCacheJson(Map json) => ConsultingHour.fromJson(
        json,
        teacherId: json["TanarUid"]?.toString() ?? "",
        teacherName: json["TanarNev"]?.toString() ?? "",
      );
}
