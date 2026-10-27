import 'package:flutter/material.dart';
import 'package:folio/helpers/motion_once.dart';
import 'package:folio/helpers/timetable_insights.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/utils/format.dart';
import 'package:intl/intl.dart';

/// Shown instead of the lesson list on a non-school day (break, special day).
class BreakCard extends StatelessWidget {
  const BreakCard({super.key, required this.span});

  final BreakSpan span;

  String get _icon {
    final n = span.name.toLowerCase();
    if (n.contains('őszi')) return '🍂';
    if (n.contains('téli')) return '❄️';
    if (n.contains('tavaszi')) return '🌷';
    return '📅';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppColors.of(context).text.withValues(alpha: 0.6);
    final d = DateFormat('MMM d.', 'hu');
    final single = span.first == span.last;
    final range = single
        ? d.format(span.first)
        : '${d.format(span.first)} – ${d.format(span.last)}';
    final left = span.daysLeft > 0 && !single ? ' · még ${span.daysLeft} nap' : '';
    final next = span.nextLesson;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(_icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(span.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$range$left', style: TextStyle(fontSize: 14, color: muted)),
            if (!single) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: span.progress,
                  minHeight: 6,
                  color: colors.secondary,
                  backgroundColor: colors.secondary.withValues(alpha: 0.15),
                ),
              ),
            ],
            if (next != null) ...[
              const SizedBox(height: 14),
              Text(
                'Következő óra: ${DateFormat('EEEE, MMM d., H:mm', 'hu').format(next.start)} · ${(next.subject.renamedTo ?? next.subject.name).capital()}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ink underline under today's date in the day picker; draws itself once
/// per app launch.
class TodayUnderline extends StatefulWidget {
  const TodayUnderline({super.key, required this.color});

  final Color color;

  @override
  State<TodayUnderline> createState() => _TodayUnderlineState();
}

class _TodayUnderlineState extends State<TodayUnderline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed) {
      if (MediaQuery.of(context).disableAnimations ||
          !MotionOnce.shouldPlay('timetable')) {
        _c.value = 1.0;
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // 200 ms wait, then 500 ms draw
          final t = Curves.easeOut
              .transform(((_c.value * 700 - 200) / 500).clamp(0.0, 1.0));
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 18 * t,
              height: 3,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        },
      );
}
