import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/day_state.dart';
import '../models/wear_lesson.dart';
import '../theme/wear_theme.dart';
import 'edge_fade.dart';
import 'ink_blot.dart';

/// The day as a line of ink: lessons hang on it, the current one stands out.
class InkTimeline extends StatelessWidget {
  final List<WearLesson> lessons;
  final DateTime now;
  const InkTimeline({super.key, required this.lessons, required this.now});

  @override
  Widget build(BuildContext context) {
    final today = lessons.where((l) => _sameDay(l.start, now)).toList();
    final current = dayStateAt(lessons, now).current;
    if (today.isNotEmpty) {
      final held = today.where((l) => !l.isCancelled).toList();
      final end = held.isEmpty
          ? null
          : held.map((l) => l.end).reduce((a, b) => a.isAfter(b) ? a : b);
      return Column(children: [
        for (final (i, l) in today.indexed)
          _Row(
            lesson: l,
            now: now,
            isCurrent: identical(l, current),
            isFirst: i == 0,
          ),
        if (end != null) _DayEnd(end: end, now: now),
      ]);
    }

    final days = <DateTime, List<WearLesson>>{};
    for (final l in lessons) {
      days
          .putIfAbsent(DateTime(l.start.year, l.start.month, l.start.day),
              () => [])
          .add(l);
    }
    final sorted = days.keys.toList()..sort();
    return Column(children: [
      for (final day in sorted) ...[
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
          child: Text(
            DateFormat('EEEE', 'hu').format(day),
            style: const TextStyle(
                color: WearColors.muted,
                fontSize: 11.0,
                fontWeight: FontWeight.w600),
          ),
        ),
        for (final (i, l) in days[day]!.indexed)
          _Row(lesson: l, now: now, isCurrent: false, isFirst: i == 0),
      ],
    ]);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

const _dryLine = Color(0xFF333745);

class _Row extends StatelessWidget {
  final WearLesson lesson;
  final DateTime now;
  final bool isCurrent;
  final bool isFirst;
  const _Row({
    required this.lesson,
    required this.now,
    required this.isCurrent,
    required this.isFirst,
  });

  static const _dotCenter = 20.0;

  Color get _dot {
    if (lesson.isCancelled) return WearColors.cancelled;
    if (lesson.isSubstitution) return WearColors.substitution;
    return isCurrent ? WearColors.ink : const Color(0xFF555A68);
  }

  Color get _cardColor {
    if (isCurrent) return WearColors.cobalt;
    if (lesson.isCancelled) return const Color(0xFF3A1A1F);
    if (lesson.isSubstitution) return const Color(0xFF3A2A14);
    return WearColors.surface;
  }

  String get _subtitle {
    if (lesson.isCancelled) return 'Elmarad';
    if (lesson.isSubstitution) return lesson.teacher;
    if (isCurrent) {
      final left = (lesson.end.difference(now).inSeconds / 60).ceil();
      return lesson.room.isEmpty
          ? 'még $left perc'
          : 'még $left perc · ${lesson.room}';
    }
    final time = DateFormat('H:mm').format(lesson.start);
    return lesson.room.isEmpty ? time : '$time · ${lesson.room}';
  }

  Color get _subtitleColor {
    if (lesson.isCancelled) return WearColors.cancelled;
    if (lesson.isSubstitution) return WearColors.substitution;
    return isCurrent ? Colors.white : WearColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    final passed = !lesson.end.isAfter(now);
    return Stack(children: [
      // Ink has flowed down to the current lesson, the rest is still dry.
      Positioned(
        left: 4.0,
        top: isFirst ? _dotCenter : 0.0,
        bottom: 0.0,
        width: 2.0,
        child: ColoredBox(color: passed ? WearColors.ink : _dryLine),
      ),
      if (isCurrent)
        Positioned(
          left: 3.0,
          top: isFirst ? _dotCenter : 0.0,
          height: isFirst ? 0.0 : _dotCenter,
          width: 4.0,
          child: const ColoredBox(color: WearColors.ink),
        ),
      Positioned(
        left: 0.5,
        top: _dotCenter - 4.5,
        child: Container(
          width: 9.0,
          height: 9.0,
          decoration: BoxDecoration(
            color: passed ? WearColors.ink : _dot,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                        color: _dot.withValues(alpha: 0.5), spreadRadius: 3.0),
                  ]
                : null,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 18.0, bottom: 5.0),
        child: EdgeFade(
          child: Opacity(
            opacity: passed ? 0.45 : 1.0,
            child: _card(_content()),
          ),
        ),
      ),
    ]);
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18.0),
        ),
        child: child,
      );

  Widget _content() => Row(children: [
        Expanded(child: _texts()),
        if (lesson.online)
          const _Mark(Icons.videocam_rounded, WearColors.inkLight),
        if (lesson.hasHomework)
          const _Mark(Icons.assignment_rounded, Color(0xFFFFE082)),
        if (lesson.hasExam)
          const _Mark(Icons.quiz_rounded, Color(0xFFF48FB1)),
      ]);

  Widget _texts() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: lesson.isCancelled
                  ? const Color(0xFFE9A3A3)
                  : Colors.white,
              fontSize: isCurrent ? 15.0 : 13.0,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              decoration:
                  lesson.isCancelled ? TextDecoration.lineThrough : null,
              decorationColor: WearColors.cancelled,
            ),
          ),
          Text(
            _subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _subtitleColor, fontSize: 11.0),
          ),
        ],
      );
}

/// The blot the line runs into: when the school day is over.
class _DayEnd extends StatelessWidget {
  final DateTime end;
  final DateTime now;
  const _DayEnd({required this.end, required this.now});

  @override
  Widget build(BuildContext context) {
    final color = end.isAfter(now) ? const Color(0xFF555A68) : WearColors.ink;
    return Row(children: [
      Transform.translate(
        offset: const Offset(-5.0, 0.0),
        child: InkBlot(size: 20.0, color: color),
      ),
      const SizedBox(width: 3.0),
      Text(
        'Vége: ${DateFormat('H:mm').format(end)}',
        style: const TextStyle(color: WearColors.muted, fontSize: 11.0),
      ),
    ]);
  }
}

class _Mark extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Mark(this.icon, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 3.0),
        child: Icon(icon, size: 14.0, color: color),
      );
}
