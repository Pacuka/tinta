import 'package:intl/intl.dart';
import 'wear_lesson.dart';

enum DayPhase { inLesson, inBreak, beforeFirst, doneToday, noLessons }

class DayState {
  final DayPhase phase;
  final WearLesson? current;
  final WearLesson? next;

  /// First known lesson on a later day.
  final WearLesson? upcoming;
  final double progress;
  final int minutesLeft;

  const DayState({
    required this.phase,
    this.current,
    this.next,
    this.upcoming,
    this.progress = 0,
    this.minutesLeft = 0,
  });
}

DayState dayStateAt(List<WearLesson> lessons, DateTime now) {
  final held = lessons.where((l) => !l.isCancelled).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final dayEnd = DateTime(now.year, now.month, now.day + 1);
  final today =
      held.where((l) => _sameDay(l.start, now)).toList(growable: false);
  final later = held.where((l) => !l.start.isBefore(dayEnd));
  final upcoming = later.isEmpty ? null : later.first;

  if (today.isEmpty) {
    return DayState(phase: DayPhase.noLessons, upcoming: upcoming);
  }

  final past = today.where((l) => !l.end.isAfter(now)).toList();
  final remaining = today.where((l) => l.end.isAfter(now)).toList();
  if (remaining.isEmpty) {
    return DayState(phase: DayPhase.doneToday, upcoming: upcoming);
  }

  final soonest = remaining.first;
  if (!soonest.start.isAfter(now)) {
    return DayState(
      phase: DayPhase.inLesson,
      current: soonest,
      next: remaining.length > 1 ? remaining[1] : null,
      progress: _progress(soonest.start, soonest.end, now),
      minutesLeft: _minutesUntil(soonest.end, now),
    );
  }

  if (past.isEmpty) {
    return DayState(
      phase: DayPhase.beforeFirst,
      next: soonest,
      minutesLeft: _minutesUntil(soonest.start, now),
    );
  }
  return DayState(
    phase: DayPhase.inBreak,
    next: soonest,
    progress: _progress(past.last.end, soonest.start, now),
    minutesLeft: _minutesUntil(soonest.start, now),
  );
}

/// The first later day with a lesson that is held.
DateTime? nextSchoolDay(List<WearLesson> lessons, DateTime now) {
  final dayEnd = DateTime(now.year, now.month, now.day + 1);
  final later = lessons
      .where((l) => !l.isCancelled && !l.start.isBefore(dayEnd))
      .map((l) => DateTime(l.start.year, l.start.month, l.start.day))
      .toList()
    ..sort();
  return later.isEmpty ? null : later.first;
}

String nextDayLabel(DateTime day, DateTime now) =>
    _sameDay(day, DateTime(now.year, now.month, now.day + 1))
        ? 'Holnap'
        : DateFormat('EEEE', 'hu').format(day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

double _progress(DateTime from, DateTime to, DateTime now) {
  final total = to.difference(from).inSeconds;
  if (total <= 0) return 0;
  return (now.difference(from).inSeconds / total).clamp(0.0, 1.0);
}

int _minutesUntil(DateTime target, DateTime now) =>
    (target.difference(now).inSeconds / 60).ceil();
