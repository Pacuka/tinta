import 'package:flutter_test/flutter_test.dart';
import 'package:folio_wear/models/wear_notification.dart';
import 'package:folio_wear/screens/notification_detail_screen.dart';

void main() {
  final base = {
    'id': 'g1',
    'title': 'Matematika',
    'body': 'Témazáró – 4',
    'type': 'grade',
    'gradeValue': 4,
    'timestamp': 0,
  };

  test('reads detail lines and text', () {
    final n = WearNotification.fromJson({
      ...base,
      'lines': ['Írásbeli', 'Súly: 200%', 7],
      'text': 'hosszú',
    });
    expect(n.lines, ['Írásbeli', 'Súly: 200%']);
    expect(n.text, 'hosszú');
  });

  test('older phones without details still parse', () {
    final n = WearNotification.fromJson(base);
    expect(n.lines, isEmpty);
    expect(n.text, '');
    expect(notificationGrade(n), 4);
  });
}
