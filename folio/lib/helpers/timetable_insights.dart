import 'package:folio_kreta_api/models/lesson.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// A day that only holds KRÉTA's "Nem órarendi nap" entries (break, special day).
bool isNonSchoolDay(List<Lesson> day) =>
    day.isNotEmpty && day.every((l) => l.subject.id == '' && !l.isEmpty);

/// "Őszi szünet (Nem órarendi nap) (Szerda)" → "Őszi szünet".
String breakName(String raw) =>
    raw.replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

class BreakSpan {
  const BreakSpan({
    required this.name,
    required this.first,
    required this.last,
    required this.daysLeft,
    required this.progress,
    this.nextLesson,
  });

  final String name;
  final DateTime first, last;

  /// Days from today to [last], today included (0 once it is over).
  final int daysLeft;

  /// 0..1, how much of the break has passed (0 for a single day).
  final double progress;

  /// First real lesson after the break, if it is in the loaded days.
  final Lesson? nextLesson;
}

/// The run of consecutive non-school days with the same name around [index].
/// Only the loaded [days] are known, so a break running past them ends at
/// the last loaded day.
BreakSpan breakSpanFor(List<List<Lesson>> days, int index, DateTime now) {
  final name = breakName(days[index].first.name);
  bool same(int i) =>
      i >= 0 &&
      i < days.length &&
      isNonSchoolDay(days[i]) &&
      breakName(days[i].first.name) == name;

  var a = index, b = index;
  while (same(a - 1)) {
    a--;
  }
  while (same(b + 1)) {
    b++;
  }

  final first = _day(days[a].first.date);
  final last = _day(days[b].first.date);
  final today = _day(now);
  final total = last.difference(first).inDays + 1;
  final left = last.difference(today).inDays + 1;
  final elapsed = today.difference(first).inDays;

  Lesson? next;
  for (var i = b + 1; i < days.length && next == null; i++) {
    for (final l in days[i]) {
      if (l.subject.id != '') {
        next = l;
        break;
      }
    }
  }

  return BreakSpan(
    name: name,
    first: first,
    last: last,
    daysLeft: left.clamp(0, total),
    progress: total <= 1 ? 0 : (elapsed / total).clamp(0.0, 1.0),
    nextLesson: next,
  );
}

/// Minutes between two lessons; null for placeholder (midnight) times or
/// when they don't follow each other.
int? gapMinutes(Lesson before, Lesson next) {
  if (before.end.hour == 0 || next.start.hour == 0) return null;
  final m = next.start.difference(before.end).inMinutes;
  return m > 0 ? m : null;
}

/// 0..1 progress of a lesson that is going on right now, else null.
double? lessonProgress(Lesson l, DateTime now) {
  if (l.start.hour == 0 || now.isBefore(l.start) || !now.isBefore(l.end)) {
    return null;
  }
  return now.difference(l.start).inSeconds / l.end.difference(l.start).inSeconds;
}

int minutesLeft(Lesson l, DateTime now) =>
    (l.end.difference(now).inSeconds / 60).ceil();
