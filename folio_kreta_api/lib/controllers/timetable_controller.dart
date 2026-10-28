// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

enum LoadType { initial, offline, loading, online }

class TimetableController extends ChangeNotifier {
  late Week currentWeek;
  int currentWeekId = -1;
  late int previousWeekId;
  List<List<Lesson>>? days;
  LoadType loadType = LoadType.initial;

  TimetableController() {
    current();
  }

  static int getWeekId(Week week) =>
      (week.start.difference(getSchoolYearStart()).inDays /
              DateTime.daysPerWeek)
          .ceil();

  static DateTime getSchoolYearStart() {
    DateTime now = DateTime.now();
    DateTime nowStart = _getYearStart(now.year);

    if (nowStart.isBefore(now)) {
      return nowStart;
    } else {
      return _getYearStart(now.year - 1);
    }
  }

  static DateTime _getYearStart(int year) {
    var s1 = DateTime(year, DateTime.september, 1);
    if (s1.weekday == DateTime.saturday) {
      s1 = s1.add(const Duration(days: 2, hours: 2));
    } else if (s1.weekday == DateTime.sunday) {
      s1 = s1.add(const Duration(days: 1, hours: 2));
    } else {
      s1 = s1.add(const Duration(hours: 2));
    }
    return s1;
  }


  // Jump shortcuts
  Future<void> next(BuildContext context) =>
      jump(Week.fromId(currentWeekId + 1), context: context);
  Future<void> previous(BuildContext context) =>
      jump(Week.fromId(currentWeekId - 1), context: context);
  void current() {
    Week week = Week.current();
    int id = getWeekId(week);

    if (id > 51) id = 51;
    if (id < 0) id = 0;

    _setWeek(Week.fromId(id));
  }

  Future<void> jump(Week week,
      {required BuildContext context,
      bool initial = false,
      bool skip = false,
      bool loader = true}) async {
    if (_setWeek(week)) return;

    loadType = LoadType.initial;

    if (loader) {
      days = null;

      // Don't start loading on init
      if (!initial) notifyListeners();
    }

    days = _sortDays(week, context: context);

    if (week != currentWeek) return;

    loadType = LoadType.loading;

    notifyListeners();

    try {
      await _fetchWeek(week, context: context).timeout(
          const Duration(seconds: 5),
          onTimeout: (() => throw "timeout"));
      loadType = LoadType.online;
    } catch (error, stack) {
      print("ERROR: TimetableController.jump: $error\n$stack");
      loadType = LoadType.offline;
    }

    if (week != currentWeek) return;

    days = _sortDays(week, context: context);

    if (week != currentWeek) return;

    // Jump to next week on weekends
    if (skip &&
        (days?.length ?? 0) > 0 &&
        days!.last.last.end.isBefore(DateTime.now())) {
      return next(context);
    }

    notifyListeners();
  }

  /// Re-reads the shown week from the provider (e.g. after a background sync).
  void refreshDays(BuildContext context) {
    // jump() is loading this week itself and will notify when done.
    if (loadType == LoadType.loading || loadType == LoadType.initial) return;
    final fresh = _sortDays(currentWeek, context: context);
    if (fresh.isEmpty && (days?.isNotEmpty ?? false)) return;
    days = fresh;
    previousWeekId = currentWeekId; // keep the selected day, no jump to today
    notifyListeners();
  }

  bool _setWeek(Week week) {
    int id = getWeekId(week);
    if (id > 51) return true; // Max 52.
    if (id < 0) return true; // Min 1.

    // Set week start to Sept. 1 of first week
    if (!_differentDate(week.start, Week.fromId(0).start)) {
      week.start = TimetableController.getSchoolYearStart();
    }

    currentWeek = week;
    previousWeekId = currentWeekId;
    currentWeekId = id;
    return false;
  }

  Future<void> _fetchWeek(Week week, {required BuildContext context}) async {
    await Future.wait([
      context.read<TimetableProvider>().fetch(week: week),
      context.read<HomeworkProvider>().fetch(from: week.start, db: false),
    ]);
  }

  List<List<Lesson>> _sortDays(Week week, {required BuildContext context}) {
    try {
      final timetableProvider = context.read<TimetableProvider>();
      return buildTimetableDays(timetableProvider.getWeek(week) ?? []);
    } catch (e) {
      log("_sortDays error: $e");
      return [];
    }
  }

}

/// Splits a week's lessons into days. Numbered lessons are ordered by time,
/// missing numbers get an empty slot, and special-day entries (no subject,
/// e.g. "Pályaorientációs nap") go on top once and never count as a slot.
List<List<Lesson>> buildTimetableDays(List<Lesson> lessons) {
  if (lessons.isEmpty) return [];

  final sorted = [...lessons]..sort((a, b) => a.date.compareTo(b.date));
  final List<List<Lesson>> days = [[]];
  for (var lesson in sorted) {
    if (days.last.isNotEmpty && _differentDate(lesson.date, days.last.last.date)) {
      days.add([]);
    }
    days.last.add(lesson);
  }

  return [for (final day0 in days) _buildDay(day0)];
}

List<Lesson> _buildDay(List<Lesson> day0) {
  bool isSpecial(Lesson l) => l.subject.id == '';
  int? slot(Lesson l) => isSpecial(l) ? null : int.tryParse(l.lessonIndex);

  final indexes = day0.map(slot).whereType<int>().toList();
  final List<Lesson> day = [];

  if (indexes.isNotEmpty) {
    final minIndex = indexes.reduce(math.min);
    final maxIndex = indexes.reduce(math.max);

    for (var i = minIndex; i <= maxIndex; i++) {
      final indexLessons = day0.where((l) => slot(l) == i).toList();

      // Empty lesson, starting right after the previous slot
      if (indexLessons.isEmpty) {
        final prev = day.where((l) => int.tryParse(l.lessonIndex) == i - 1);
        if (prev.isNotEmpty) {
          indexLessons.add(Lesson.fromJson({
            'isEmpty': true,
            'Oraszam': i,
            'KezdetIdopont':
                prev.last.start.add(const Duration(seconds: 1)).toIso8601String(),
          }));
        }
      }

      day.addAll(indexLessons);
    }
  }

  // Additional lessons without a number
  day.addAll(day0.where((l) => !isSpecial(l) && int.tryParse(l.lessonIndex) == null));

  day.sort((a, b) => a.start.compareTo(b.start));

  // Special dates on top
  day.insertAll(0, day0.where(isSpecial));

  return day;
}

bool _differentDate(DateTime a, DateTime b) =>
    !(a.year == b.year && a.month == b.month && a.day == b.day);
