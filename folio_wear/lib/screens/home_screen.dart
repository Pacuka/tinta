import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/wear_lesson.dart';
import '../providers/wear_data_provider.dart';
import '../widgets/wear_curved_scrollbar.dart';

// HyperOS WearOS design tokens
const _kCardBg = Color(0xFF1C1C1E);
// Round screen: keep content away from the curved edge.
const _kHPad = 22.0;
const _kRadius = 16.0;
const _kItemSpacing = 4.0;

class HomeScreen extends StatelessWidget {
  final ScrollController scrollController;
  const HomeScreen({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Consumer<WearDataProvider>(builder: (context, data, _) {
        final lessons = data.todayLessons;
        return lessons.isEmpty
            ? _EmptyState(data: data)
            : _LessonList(
                lessons: lessons,
                data: data,
                scrollController: scrollController,
              );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final WearDataProvider data;
  const _EmptyState({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = data.lastSync != null
        ? 'Frissítve: ${DateFormat('HH:mm').format(data.lastSync!)}'
        : 'Nincs szinkronizálva';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Icon(Icons.school_rounded,
                  size: 28.0, color: cs.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Nincs óra ma',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10.0),
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: data.requestSync,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22.0, vertical: 9.0),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Text(
                  'Frissítés',
                  style: TextStyle(
                      color: cs.primary,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LessonList extends StatelessWidget {
  final List<WearLesson> lessons;
  final WearDataProvider data;
  final ScrollController scrollController;

  const _LessonList({
    required this.lessons,
    required this.data,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return WearCurvedScrollbar(
      controller: scrollController,
      child: CustomScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Date header
          SliverPadding(
            padding: const EdgeInsets.only(
                top: 30.0, left: 28.0, right: 28.0, bottom: 8.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                DateFormat('EEEE, MMM d', 'hu').format(now).replaceFirstMapped(
                    RegExp(r'^.'), (m) => m[0]!.toUpperCase()),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2),
              ),
            ),
          ),
          // Lesson items
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final lesson = lessons[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: _kItemSpacing),
                  child: _LessonTile(
                    lesson: lesson,
                    isNow: lesson.isActiveAt(now),
                    isPast: lesson.end.isBefore(now),
                    isNext: !lesson.isActiveAt(now) &&
                        !lesson.end.isBefore(now) &&
                        data.nextLesson?.id == lesson.id,
                  ),
                );
              },
              childCount: lessons.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 52.0)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final WearLesson lesson;
  final bool isNow;
  final bool isPast;
  final bool isNext;

  const _LessonTile({
    required this.lesson,
    required this.isNow,
    required this.isPast,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('H:mm');

    // HyperOS card background logic
    Color cardBg;
    Color accentColor;

    if (lesson.isCancelled) {
      cardBg = const Color(0xFF3D1212);
      accentColor = const Color(0xFFEF9A9A);
    } else if (lesson.isSubstitution) {
      cardBg = const Color(0xFF3D2200);
      accentColor = const Color(0xFFFFCC80);
    } else if (isNow) {
      cardBg = cs.primary.withValues(alpha: 0.22);
      accentColor = cs.primary;
    } else if (isNext) {
      cardBg = const Color(0xFF0D3D1F);
      accentColor = const Color(0xFF80CBC4);
    } else {
      cardBg = _kCardBg;
      accentColor = Colors.white.withValues(alpha: isPast ? 0.3 : 0.55);
    }

    final double textAlpha = isPast && !isNow ? 0.4 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 9.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time + index column
            SizedBox(
              width: 30.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${lesson.lessonIndex}',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w800,
                      color: isNow
                          ? cs.primary
                          : Colors.white.withValues(alpha: textAlpha),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    timeFmt.format(lesson.start),
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Colors.white
                          .withValues(alpha: 0.38 * textAlpha),
                      height: 1.2,
                    ),
                  ),
                  Text(
                    timeFmt.format(lesson.end),
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Colors.white
                          .withValues(alpha: 0.28 * textAlpha),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              width: 1.0,
              height: 36.0,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              color: accentColor.withValues(alpha: isNow ? 0.6 : 0.2),
            ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.isSubstitution
                              ? '${lesson.subject} •'
                              : lesson.subject,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white
                                .withValues(alpha: textAlpha),
                            decoration: lesson.isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor:
                                const Color(0xFFEF9A9A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lesson.room.isNotEmpty) ...[
                        const SizedBox(width: 4.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color:
                                accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            lesson.room,
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w600,
                              color: accentColor.withValues(
                                  alpha: 0.9 * textAlpha),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (lesson.teacher.isNotEmpty && !lesson.isCancelled) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      lesson.teacher,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white
                            .withValues(alpha: 0.42 * textAlpha),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Status badges row
                  if (lesson.online ||
                      lesson.hasHomework ||
                      lesson.hasExam) ...[
                    const SizedBox(height: 5.0),
                    Wrap(
                      spacing: 4.0,
                      children: [
                        if (lesson.online)
                          _StatusBadge(
                              label: 'Online',
                              icon: Icons.videocam_rounded,
                              color: Colors.tealAccent),
                        if (lesson.hasHomework)
                          _StatusBadge(
                              icon: Icons.assignment_rounded,
                              color: const Color(0xFFFFF176)),
                        if (lesson.hasExam)
                          _StatusBadge(
                              icon: Icons.quiz_rounded,
                              color: const Color(0xFFFFAB91)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? label;
  final IconData icon;
  final Color color;

  const _StatusBadge({
    this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9.0, color: color),
          if (label != null) ...[
            const SizedBox(width: 3.0),
            Text(
              label!,
              style: TextStyle(
                  fontSize: 8.5,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
