import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio_kreta_api/models/week.dart';

const _todoDays = 7;
const _maxTodos = 15;

class WearTodoItem {
  final String id;
  final String type; // "homework" | "exam"
  final String subject;
  final DateTime due;
  /// For the watch's detail view: exam topic, short facts, homework text.
  final String title;
  final List<String> lines;
  final String text;

  const WearTodoItem({
    required this.id,
    required this.type,
    required this.subject,
    required this.due,
    this.title = '',
    this.lines = const [],
    this.text = '',
  });
}

/// Long text for the watch's detail view, cut so the message stays small.
String wearDetailText(String text) {
  final t = text.trim();
  return t.length <= 600 ? t : '${t.substring(0, 600).trimRight()}…';
}

String wearSubjectName(GradeSubject subject) =>
    (subject.renamedTo?.isNotEmpty ?? false)
        ? subject.renamedTo!
        : subject.name;

/// Tanulmányi átlag: the mean of the rounded subject marks, the same value as
/// the "tárgyak átl." badge on the Grades page.
double wearStudyAverage(
    Iterable<({double average, double threshold})> subjects) {
  if (subjects.isEmpty) return 0.0;
  final marks = subjects.map((s) {
    final base = s.average.floor();
    return (s.average - base) >= s.threshold ? base + 1.0 : base.toDouble();
  });
  return marks.reduce((a, b) => a + b) / subjects.length;
}

/// Study average and upcoming homework/exams for /folio/extras.
String buildWearExtras({
  required List<WearTodoItem> items,
  required double? average,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day + _todoDays + 1);
  final todos = items
      .where((t) => !t.due.isBefore(today) && t.due.isBefore(end))
      .toList()
    ..sort((a, b) => a.due.compareTo(b.due));

  return jsonEncode({
    'average': average == null || average <= 0
        ? null
        : double.parse(average.toStringAsFixed(2)),
    'todos': todos
        .take(_maxTodos)
        .map((t) => {
              'id': t.id,
              'type': t.type,
              'subject': t.subject,
              'due': t.due.millisecondsSinceEpoch,
              if (t.title.isNotEmpty) 'title': t.title,
              if (t.lines.isNotEmpty) 'lines': t.lines,
              if (t.text.isNotEmpty) 'text': t.text,
            })
        .toList(),
  });
}

/// From Friday the watch's "next school day" is in next week.
bool needsNextWeek(DateTime now) => now.weekday >= DateTime.friday;

Future<void> fetchNextWeekIfNeeded(
    DateTime now, Future<void> Function(Week week) fetch) async {
  if (!needsNextWeek(now)) return;
  try {
    await fetch(Week.fromDate(now).next());
  } catch (e) {
    if (kDebugMode) print('WearExtras: next week fetch failed: $e');
  }
}
