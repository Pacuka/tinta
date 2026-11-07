import 'package:folio_kreta_api/models/attachment.dart';
import 'package:folio_kreta_api/client/api.dart';

import 'subject.dart';
import 'teacher.dart';

class Homework {
  Map? json;
  DateTime date;
  DateTime lessonDate;
  DateTime deadline;
  bool byTeacher;
  bool homeworkEnabled;
  Teacher teacher;
  String content;
  GradeSubject subject;
  String group;
  List<HomeworkAttachment> attachments;
  String id;

  /// When Tinta noticed the last change. KRÉTA itself sends no modification
  /// date, see [Homework.signature].
  DateTime? modifiedAt;

  /// Earlier versions Tinta saw, oldest first.
  List<HomeworkVersion> previous;

  bool get modified => modifiedAt != null;

  Homework({
    required this.date,
    required this.lessonDate,
    required this.deadline,
    required this.byTeacher,
    required this.homeworkEnabled,
    required this.teacher,
    required this.content,
    required this.subject,
    required this.group,
    required this.attachments,
    required this.id,
    this.modifiedAt,
    this.previous = const [],
    this.json,
  });

  /// What a student would notice changing: text, deadline, attachments.
  static String signature(Map json) => [
        "${json["Szoveg"] ?? ""}".trim(),
        "${json["HataridoDatuma"] ?? ""}",
        ...((json["Csatolmanyok"] ?? []) as List)
            .cast<Map>()
            .map((a) => "${a["Uid"]}")
            .toList()
          ..sort(),
      ].join("\u0000");

  // Stored inside [json], so they survive the database like the rest.
  static const modifiedKey = "TintaModositva";
  static const previousKey = "TintaKorabbi";
  static const maxPrevious = 10;

  /// Compares [fresh] with the [old] copy: a change saves the old version and
  /// stamps [now]; otherwise what the old copy knew is carried over.
  static void carryModified(Map? old, Map fresh, {DateTime? now}) {
    if (old == null) return;
    var modified = old[modifiedKey];
    final previous = ((old[previousKey] ?? []) as List).cast<Map>().toList();
    if (signature(old) != signature(fresh)) {
      modified = (now ?? DateTime.now()).toIso8601String();
      previous.add({
        "Szoveg": old["Szoveg"],
        "HataridoDatuma": old["HataridoDatuma"],
        "Csatolmanyok": old["Csatolmanyok"],
        "Mikor": modified,
      });
    }
    if (modified != null) fresh[modifiedKey] = modified;
    if (previous.isNotEmpty) {
      fresh[previousKey] = previous.length > maxPrevious
          ? previous.sublist(previous.length - maxPrevious)
          : previous;
    }
  }

  factory Homework.fromJson(Map json) {
    return Homework(
      id: json["Uid"] ?? "",
      date: json["RogzitesIdopontja"] != null
          ? DateTime.parse(json["RogzitesIdopontja"]).toLocal()
          : DateTime(0),
      lessonDate: json["FeladasDatuma"] != null
          ? DateTime.parse(json["FeladasDatuma"]).toLocal()
          : DateTime(0),
      deadline: json["HataridoDatuma"] != null
          ? DateTime.parse(json["HataridoDatuma"]).toLocal()
          : DateTime(0),
      byTeacher: json["IsTanarRogzitette"] ?? true,
      homeworkEnabled: json["IsTanuloHaziFeladatEnabled"] ?? false,
      teacher: Teacher.fromString((json["RogzitoTanarNeve"] ?? "").trim()),
      content: (json["Szoveg"] ?? "").trim(),
      subject: GradeSubject.fromJson(json["Tantargy"] ?? {}),
      group: json["OsztalyCsoport"] != null
          ? json["OsztalyCsoport"]["Uid"] ?? ""
          : "",
      attachments: ((json["Csatolmanyok"] ?? []) as List)
          .cast<Map>()
          .map((Map json) => HomeworkAttachment.fromJson(json))
          .toList(),
      modifiedAt: DateTime.tryParse("${json[modifiedKey]}"),
      previous: ((json[previousKey] ?? []) as List)
          .cast<Map>()
          .map(HomeworkVersion.fromJson)
          .toList(),
      json: json,
    );
  }
}

class HomeworkVersion {
  String content;
  DateTime? deadline;
  List<String> attachments;

  /// When Tinta noticed that this version was replaced.
  DateTime replacedAt;

  HomeworkVersion({
    required this.content,
    required this.replacedAt,
    this.deadline,
    this.attachments = const [],
  });

  factory HomeworkVersion.fromJson(Map json) => HomeworkVersion(
        content: "${json["Szoveg"] ?? ""}".trim(),
        replacedAt: DateTime.parse(json["Mikor"]).toLocal(),
        deadline: json["HataridoDatuma"] != null
            ? DateTime.parse(json["HataridoDatuma"]).toLocal()
            : null,
        attachments: ((json["Csatolmanyok"] ?? []) as List)
            .cast<Map>()
            .map((a) => "${a["Nev"] ?? ""}")
            .toList(),
      );
}

class HomeworkAttachment {
  Map? json;
  String id;
  String name;
  String type;

  HomeworkAttachment(
      {required this.id, this.name = "", this.type = "", this.json});

  factory HomeworkAttachment.fromJson(Map json) {
    return HomeworkAttachment(
      id: json["Uid"] ?? "",
      name: json["Nev"] ?? "",
      type: json["Tipus"] ?? "",
      json: json,
    );
  }

  String downloadUrl(String iss) =>
      KretaAPI.downloadHomeworkAttachments(iss, id, type);
  bool get isImage => isImageName(name);
}
