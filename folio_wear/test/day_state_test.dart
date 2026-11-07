import 'package:flutter_test/flutter_test.dart';
import 'package:folio_wear/models/day_state.dart';
import 'package:folio_wear/models/wear_lesson.dart';
import 'package:intl/date_symbol_data_local.dart';

WearLesson lesson(DateTime start, DateTime end, {String status = 'normal'}) =>
    WearLesson(
      id: '$start',
      subject: 'Tárgy',
      room: '101',
      teacher: 'Minta Tanár',
      start: start,
      end: end,
      lessonIndex: 1,
      status: status,
      online: false,
    );

DateTime t(int h, int m, [int s = 0]) => DateTime(2026, 11, 9, h, m, s);

void main() {
  final first = lesson(t(8, 0), t(8, 45));
  final second = lesson(t(9, 0), t(9, 45));
  final today = [first, second];
  final tomorrow = lesson(
      DateTime(2026, 11, 10, 8, 0), DateTime(2026, 11, 10, 8, 45));
  final yesterday =
      lesson(DateTime(2026, 11, 8, 8, 0), DateTime(2026, 11, 8, 8, 45));

  test('during lesson', () {
    final s = dayStateAt(today, t(8, 21));
    expect(s.phase, DayPhase.inLesson);
    expect(s.current, first);
    expect(s.next, second);
    expect(s.minutesLeft, 24);
    expect(s.progress, closeTo(21 / 45, 0.001));
  });

  test('exactly at start is in lesson', () {
    final s = dayStateAt(today, t(8, 0));
    expect(s.phase, DayPhase.inLesson);
    expect(s.current, first);
  });

  test('exactly at end is break', () {
    final s = dayStateAt(today, t(8, 45));
    expect(s.phase, DayPhase.inBreak);
    expect(s.next, second);
    expect(s.minutesLeft, 15);
    expect(s.progress, 0);
  });

  test('partial minute rounds up', () {
    expect(dayStateAt(today, t(8, 21, 30)).minutesLeft, 24);
  });

  test('before first', () {
    final s = dayStateAt(today, t(7, 10));
    expect(s.phase, DayPhase.beforeFirst);
    expect(s.next, first);
    expect(s.minutesLeft, 50);
    expect(s.progress, 0);
  });

  test('done today with known upcoming', () {
    final s = dayStateAt([...today, tomorrow], t(15, 0));
    expect(s.phase, DayPhase.doneToday);
    expect(s.upcoming, tomorrow);
  });

  test('cancelled lesson is skipped', () {
    final s = dayStateAt(
        [lesson(t(8, 0), t(8, 45), status: 'cancelled'), second], t(8, 10));
    expect(s.phase, DayPhase.beforeFirst);
    expect(s.next, second);
  });

  test('all cancelled today', () {
    final s = dayStateAt([
      lesson(t(8, 0), t(8, 45), status: 'cancelled'),
      lesson(t(9, 0), t(9, 45), status: 'cancelled'),
    ], t(8, 10));
    expect(s.phase, DayPhase.noLessons);
  });

  test('no lessons today, later lesson known', () {
    final s = dayStateAt([tomorrow], t(10, 0));
    expect(s.phase, DayPhase.noLessons);
    expect(s.upcoming, tomorrow);
  });

  test('stale data', () {
    final s = dayStateAt([yesterday], t(10, 0));
    expect(s.phase, DayPhase.noLessons);
    expect(s.upcoming, isNull);
  });

  test('empty list', () {
    expect(dayStateAt(const [], t(10, 0)).phase, DayPhase.noLessons);
  });

  final monday = DateTime(2026, 11, 9, 16);
  final friday = DateTime(2026, 11, 13, 16);

  test('next school day skips the weekend', () {
    final next = lesson(DateTime(2026, 11, 16, 8), DateTime(2026, 11, 16, 9));
    expect(nextSchoolDay([next], friday), DateTime(2026, 11, 16));
  });

  test('no later lesson gives null', () {
    expect(nextSchoolDay([first], monday), isNull);
  });

  test('cancelled only day is skipped', () {
    expect(
        nextSchoolDay([
          lesson(DateTime(2026, 11, 10, 8), DateTime(2026, 11, 10, 9),
              status: 'cancelled'),
          lesson(DateTime(2026, 11, 11, 8), DateTime(2026, 11, 11, 9)),
        ], monday),
        DateTime(2026, 11, 11));
  });

  test('label is tomorrow', () {
    expect(nextDayLabel(DateTime(2026, 11, 10), monday), 'Holnap');
  });

  test('label is weekday', () async {
    await initializeDateFormatting('hu');
    expect(nextDayLabel(DateTime(2026, 11, 16), friday), 'hétfő');
  });

  test('sunday says tomorrow, saturday says the day', () async {
    await initializeDateFormatting('hu');
    final nextMonday = DateTime(2026, 11, 16);
    expect(nextDayLabel(nextMonday, DateTime(2026, 11, 15, 10)), 'Holnap');
    expect(nextDayLabel(nextMonday, DateTime(2026, 11, 14, 10)), 'hétfő');
  });
}
