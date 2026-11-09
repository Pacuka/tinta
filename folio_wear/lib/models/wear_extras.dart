import 'dart:convert';

class WearTodo {
  final String id;
  final String type; // "homework" | "exam"
  final String subject;
  final DateTime due;
  /// Detail view: exam topic, short facts, homework text (phone 1.6.2+).
  final String title;
  final List<String> lines;
  final String text;

  const WearTodo({
    required this.id,
    required this.type,
    required this.subject,
    required this.due,
    this.title = '',
    this.lines = const [],
    this.text = '',
  });

  bool get isExam => type == 'exam';

  factory WearTodo.fromJson(Map<String, dynamic> json) => WearTodo(
        id: json['id'] as String,
        type: json['type'] as String,
        subject: json['subject'] as String,
        due: DateTime.fromMillisecondsSinceEpoch(json['due'] as int),
        title: json['title'] as String? ?? '',
        lines: (json['lines'] as List?)?.whereType<String>().toList() ??
            const [],
        text: json['text'] as String? ?? '',
      );
}

/// Sent by the phone from version 1.6.1, null with an older phone app.
class WearExtras {
  final double? average;
  final List<WearTodo> todos;

  const WearExtras({required this.average, required this.todos});

  static WearExtras? tryParse(String json) {
    try {
      final raw = jsonDecode(json) as Map<String, dynamic>;
      return WearExtras(
        average: (raw['average'] as num?)?.toDouble(),
        todos: (raw['todos'] as List<dynamic>)
            .map((e) => WearTodo.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => a.due.compareTo(b.due)),
      );
    } catch (_) {
      return null;
    }
  }

  /// The saved list can be days old when the phone is away.
  List<WearTodo> upcoming(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return todos.where((t) => !t.due.isBefore(today)).toList();
  }
}
