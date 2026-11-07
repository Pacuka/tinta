import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/day_state.dart';
import '../models/wear_lesson.dart';
import '../theme/wear_theme.dart';
import 'minute_ticker.dart';
import 'progress_ring.dart';

/// Start page: what is happening now, readable at a glance.
class HomeRing extends StatelessWidget {
  final List<WearLesson> lessons;
  final DateTime Function() clock;
  final VoidCallback? onRefresh;

  const HomeRing({
    super.key,
    required this.lessons,
    this.clock = DateTime.now,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => MinuteTicker(builder: _build);

  Widget _build(BuildContext context) {
    final now = clock();
    final state = dayStateAt(lessons, now);
    final ring = switch (state.phase) {
      DayPhase.inLesson => WearColors.ink,
      DayPhase.inBreak => WearColors.breakTeal,
      DayPhase.beforeFirst => WearColors.ink,
      _ => null,
    };
    return LayoutBuilder(builder: (context, box) {
      final width = box.biggest.shortestSide * 0.76;
      return Stack(fit: StackFit.expand, children: [
        if (ring != null) ProgressRing(progress: state.progress, color: ring),
        Center(
          child: SizedBox(
            width: width,
            height: width,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _content(state, now),
                ),
              ),
            ),
          ),
        ),
      ]);
    });
  }

  List<Widget> _content(DayState s, DateTime now) => switch (s.phase) {
        DayPhase.inLesson => [
            _Small('${s.current!.lessonIndex}. óra'),
            _Title(s.current!.subject),
            _Minutes(s.minutesLeft, WearColors.inkLight),
            _RoomChip(s.current!.room),
            if (s.next != null) ...[
              const SizedBox(height: 3.0),
              _Small('Utána: ${s.next!.subject}, ${s.next!.room}'),
            ],
          ],
        DayPhase.inBreak => [
            const _Small('Szünet'),
            _Minutes(s.minutesLeft, WearColors.breakTeal),
            _Title(s.next!.subject),
            _RoomChip(s.next!.room),
          ],
        DayPhase.beforeFirst => [
            const _Small('Első óra'),
            _Title(s.next!.subject),
            if (s.minutesLeft <= 60)
              _Minutes(s.minutesLeft, WearColors.inkLight)
            else
              _Big(_time(s.next!.start), WearColors.inkLight),
            _RoomChip(s.next!.room),
          ],
        DayPhase.doneToday => [
            const _Title('Mára végeztél'),
            ..._upcoming(s, now),
          ],
        DayPhase.noLessons => [
            const _Title('Ma nincs órád'),
            ..._upcoming(s, now),
            if (onRefresh != null) ...[
              const SizedBox(height: 8.0),
              _RefreshChip(onRefresh!),
            ],
          ],
      };

  List<Widget> _upcoming(DayState s, DateTime now) {
    final l = s.upcoming;
    if (l == null) return const [];
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final isTomorrow = l.start.year == tomorrow.year &&
        l.start.month == tomorrow.month &&
        l.start.day == tomorrow.day;
    final when = isTomorrow
        ? _time(l.start)
        : '${DateFormat('EEEE', 'hu').format(l.start)} ${_time(l.start)}';
    return [
      const SizedBox(height: 5.0),
      _Small(isTomorrow ? 'Holnap első óra' : 'Következő óra'),
      Text(
        '$when · ${l.subject}',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: WearColors.inkLight, fontSize: 13.0),
      ),
    ];
  }

  String _time(DateTime t) => DateFormat('H:mm').format(t);
}

class _Small extends StatelessWidget {
  final String text;
  const _Small(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: WearColors.muted, fontSize: 11.0),
      );
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: Colors.white, fontSize: 19.0, fontWeight: FontWeight.w600),
      );
}

class _Big extends StatelessWidget {
  final String text;
  final Color color;
  const _Big(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            color: color,
            fontSize: 30.0,
            fontWeight: FontWeight.w300,
            height: 1.15),
      );
}

class _Minutes extends StatelessWidget {
  final int minutes;
  final Color color;
  const _Minutes(this.minutes, this.color);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          _Big('$minutes', color),
          const SizedBox(width: 3.0),
          const Text('perc',
              style: TextStyle(color: WearColors.muted, fontSize: 12.0)),
        ],
      );
}

class _RoomChip extends StatelessWidget {
  final String room;
  const _RoomChip(this.room);

  @override
  Widget build(BuildContext context) {
    if (room.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: WearColors.cobalt,
          borderRadius: BorderRadius.circular(99.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.door_front_door_rounded,
                size: 12.0, color: Colors.white),
            const SizedBox(width: 3.0),
            Flexible(
              child: Text(
                room,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshChip extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshChip(this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: WearColors.cobalt.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: const Text(
            'Frissítés',
            style: TextStyle(
                color: WearColors.inkLight,
                fontSize: 13.0,
                fontWeight: FontWeight.w600),
          ),
        ),
      );
}
