class WearNotification {
  final String id;
  final String title;
  final String body;
  final String type; // "grade" | "absence" | "message" | "note" | "exam" | "homework"
  final int? gradeValue; // 1-5; null for non-grade types
  final DateTime timestamp;
  /// Short facts for the detail view (teacher, weight, …); empty from
  /// phones older than 1.6.2.
  final List<String> lines;
  /// Longer text for the detail view (message or note text).
  final String text;

  const WearNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.gradeValue,
    required this.timestamp,
    this.lines = const [],
    this.text = '',
  });

  factory WearNotification.fromJson(Map<String, dynamic> json) {
    return WearNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      gradeValue: json['gradeValue'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      lines: (json['lines'] as List?)?.whereType<String>().toList() ?? const [],
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'gradeValue': gradeValue,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'lines': lines,
        'text': text,
      };
}
