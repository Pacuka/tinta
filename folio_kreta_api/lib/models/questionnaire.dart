/// "PedTér" teacher questionnaires (Pedter/Kerdoivek): one per teacher,
/// answered with 1-5 grades and free text, sent once.
enum QuestionType { grade, text }

const questionnaireTextLimit = 1000;

class Question {
  Question({required this.id, required this.text, required this.type});

  final int id;
  final String text;
  final QuestionType type;

  static Question? fromJson(Map json) {
    final id = json["Id"];
    if (id is! int) return null;
    final t = "${json["Tipus"] ?? ""}".toLowerCase();
    return Question(
      id: id,
      text: "${json["Text"] ?? ""}".trim(),
      type: t == "text" ? QuestionType.text : QuestionType.grade,
    );
  }

  Map toJson() => {
        "Id": id,
        "Text": text,
        "Tipus": type == QuestionType.text ? "Text" : "Grade",
      };
}

class TeacherQuestionnaire {
  TeacherQuestionnaire({
    required this.teacherId,
    required this.teacherName,
    required this.subjects,
    required this.questionnaireId,
    required this.questions,
    this.deadline,
  });

  final int teacherId;
  final String teacherName;

  /// TanitottTantargyak, as KRÉTA writes it.
  final String subjects;
  final int questionnaireId;
  final List<Question> questions;
  final DateTime? deadline;

  static DateTime? _time(Object? v) {
    if (v is! String || v.isEmpty) return null;
    try {
      return DateTime.parse(v).toLocal();
    } catch (_) {
      return null;
    }
  }

  static TeacherQuestionnaire? fromJson(Map json) {
    final teacherId = json["TanarId"];
    final q = json["Kerdoiv"];
    if (teacherId is! int || q is! Map || q["Id"] is! int) return null;
    final questions = (q["Kerdesek"] is List ? q["Kerdesek"] as List : const [])
        .whereType<Map>()
        .map(Question.fromJson)
        .nonNulls
        .toList();
    if (questions.isEmpty) return null;
    return TeacherQuestionnaire(
      teacherId: teacherId,
      teacherName: "${json["TanarNev"] ?? ""}".trim(),
      subjects: "${json["TanitottTantargyak"] ?? ""}".trim(),
      questionnaireId: q["Id"] as int,
      questions: questions,
      deadline: _time(q["BekuldesVege"]),
    );
  }

  Map toJson() => {
        "TanarId": teacherId,
        "TanarNev": teacherName,
        "TanitottTantargyak": subjects,
        "Kerdoiv": {
          "Id": questionnaireId,
          "BekuldesVege": deadline?.toUtc().toIso8601String(),
          "Kerdesek": questions.map((q) => q.toJson()).toList(),
        },
      };

  /// Every grade question has 1-5, every text question has some text
  /// (the official app's rule for enabling "Send").
  bool isComplete(Map<int, String> answers) => questions.every((q) {
        final a = answers[q.id]?.trim() ?? "";
        if (q.type == QuestionType.text) {
          return a.isNotEmpty && a.length <= questionnaireTextLimit;
        }
        final n = int.tryParse(a);
        return n != null && n >= 1 && n <= 5;
      });

  /// Body of POST Pedter/Kerdoiv.
  Map<String, Object> submitBody(Map<int, String> answers) => {
        "TanarId": teacherId,
        "Valaszok": [
          for (final q in questions)
            {"KerdesId": q.id, "Valasz": (answers[q.id] ?? "").trim()},
        ],
      };
}

/// The whole Pedter/Kerdoivek answer: a sending window and the list.
class QuestionnaireRound {
  QuestionnaireRound({this.start, this.end, required this.items});

  final DateTime? start;
  final DateTime? end;
  final List<TeacherQuestionnaire> items;

  static QuestionnaireRound fromJson(Map json) => QuestionnaireRound(
        start: TeacherQuestionnaire._time(json["BekuldesKezdete"]),
        end: TeacherQuestionnaire._time(json["BekuldesVege"]),
        items: (json["Kerdoivek"] is List ? json["Kerdoivek"] as List : const [])
            .whereType<Map>()
            .map(TeacherQuestionnaire.fromJson)
            .nonNulls
            .toList(),
      );

  Map toJson() => {
        "BekuldesKezdete": start?.toUtc().toIso8601String(),
        "BekuldesVege": end?.toUtc().toIso8601String(),
        "Kerdoivek": items.map((i) => i.toJson()).toList(),
      };

  bool isOpen(DateTime now) =>
      (start == null || !now.isBefore(start!)) &&
      (end == null || now.isBefore(end!));
}
