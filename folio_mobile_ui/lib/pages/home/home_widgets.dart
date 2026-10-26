// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/helpers/average_helper.dart';
import 'package:folio/models/home_layout.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/utils/format.dart';
import 'package:folio/ui/widgets/grade/grade_tile.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/models/message.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio_mobile_ui/pages/home/live_card/live_card.dart';

import 'home_widgets.i18n.dart' show HomeWidgetsLocalization;

// Helper to avoid `.i18n` extension conflicts
String _t(String key) => HomeWidgetsLocalization(key).i18n;

// ─── Card wrapper ─────────────────────────────────────────────────────────────

class _HomeWidgetCard extends StatelessWidget {
  const _HomeWidgetCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).text.withOpacity(0.6),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

Widget _emptyLabel(BuildContext context) => Text(
      _t('no_data'),
      style: TextStyle(
        fontSize: 13,
        color: AppColors.of(context).text.withOpacity(0.45),
      ),
    );

// ─── 1. GreetingWidget ────────────────────────────────────────────────────────

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key});

  String _computeGreeting(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final now = DateTime.now();

    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    final String firstName = settings.presentationMode
        ? "János"
        : (nameParts.length > 1 ? nameParts[1] : nameParts[0]);

    // Use HomeWidgetsLocalization for greeting keys (greeting keys are duplicated there)
    if (now.isBefore(DateTime(now.year, DateTime.august, 31)) &&
        now.isAfter(DateTime(now.year, DateTime.june, 14))) {
      return localizeFill(_t('goodrest'), [firstName]);
    } else if (now.month == user.student?.birth.month &&
        now.day == user.student?.birth.day) {
      return localizeFill(_t('happybirthday'), [firstName]);
    } else if (now.month == DateTime.october &&
        now.day == 26 &&
        now.year > 2026) {
      final age = now.year - 2026;
      return localizeFill(_t('folioopen'), [age]);
    } else if (now.month == DateTime.december && now.day >= 24 && now.day <= 26) {
      return localizeFill(_t('merryxmas'), [firstName]);
    } else if (now.month == DateTime.january && now.day == 1) {
      return localizeFill(_t('happynewyear'), [firstName]);
    } else if (settings.welcomeMessage.replaceAll(' ', '').isNotEmpty) {
      return localizeFill(settings.welcomeMessage, [firstName]);
    } else if (now.hour >= 21 || now.hour < 4) {
      return localizeFill(_t('goodnight'), [firstName]);
    } else if (now.hour >= 18) {
      return localizeFill(_t('goodevening'), [firstName]);
    } else if (now.hour >= 12) {
      return localizeFill(_t('goodafternoon'), [firstName]);
    } else {
      return localizeFill(_t('goodmorning'), [firstName]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final greeting = _computeGreeting(context);
    final greetingColor = Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface;
    final dateColor = AppColors.of(context).text.withOpacity(0.55);
    final dateStr = DateFormat('EEEE, MMM d', I18n.locale.countryCode)
        .format(DateTime.now())
        .capital();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            overflow: TextOverflow.fade,
            style: settings.fontFamily.isNotEmpty && settings.titleOnlyFont
                ? GoogleFonts.getFont(
                    settings.fontFamily,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: greetingColor,
                    ),
                  )
                : TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: greetingColor,
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: dateColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. LiveCardHomeWidget ────────────────────────────────────────────────────

class LiveCardHomeWidget extends StatelessWidget {
  const LiveCardHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: const LiveCard(),
    );
  }
}

// ─── 3. GradeAverageWidget ────────────────────────────────────────────────────

class GradeAverageWidget extends StatelessWidget {
  const GradeAverageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final grades = Provider.of<GradeProvider>(context)
        .grades
        .where((g) => g.type == GradeType.midYear && g.value.value > 0)
        .toList();
    final avg = grades.isEmpty ? 0.0 : AverageHelper.averageEvals(grades);
    final rounded = avg.isNaN ? 0 : avg.round().clamp(0, 5);

    final fakeValue = GradeValue(rounded, '', '', 100);

    return _HomeWidgetCard(
      title: _t('grade_average'),
      icon: Icons.star_rounded,
      iconColor: Colors.amber,
      children: [
        Center(
          child: Column(
            children: [
              GradeValueWidget(fakeValue, size: 44, fill: true),
              const SizedBox(height: 6),
              Text(
                avg.isNaN ? '-' : avg.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.of(context).text.withOpacity(0.6),
                ),
              ),
              Text(
                _t('overall_average'),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.of(context).text.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 4. RecentGradesWidget ────────────────────────────────────────────────────

class RecentGradesWidget extends StatelessWidget {
  const RecentGradesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final grades = Provider.of<GradeProvider>(context)
        .grades
        .where((g) => g.type == GradeType.midYear && g.value.value > 0)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = grades.take(5).toList();

    return _HomeWidgetCard(
      title: _t('recent_grades'),
      icon: Icons.grade_rounded,
      iconColor: Colors.orange,
      children: recent.isEmpty
          ? [_emptyLabel(context)]
          : recent.map((g) {
              final subjectName = g.subject.renamedTo ??
                  g.subject.name.escapeHtml().capital();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    GradeValueWidget(g.value, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subjectName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      DateFormat('MM.dd').format(g.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).text.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

// ─── 5. SubjectAveragesWidget ─────────────────────────────────────────────────

class SubjectAveragesWidget extends StatelessWidget {
  const SubjectAveragesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final avgs = Provider.of<GradeProvider>(context).subjectAverages;
    final sorted = [...avgs]..sort((a, b) => b.average.compareTo(a.average));
    final top = sorted.take(5).toList();

    return _HomeWidgetCard(
      title: _t('subject_averages'),
      icon: Icons.bar_chart_rounded,
      iconColor: Colors.blue,
      children: top.isEmpty
          ? [_emptyLabel(context)]
          : top.map((sa) {
              final name = sa.subject.renamedTo ??
                  sa.subject.name.escapeHtml().capital();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          sa.average.toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (sa.average / 5).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

// ─── 6. UpcomingExamWidget ────────────────────────────────────────────────────

class UpcomingExamWidget extends StatelessWidget {
  const UpcomingExamWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exams = Provider.of<ExamProvider>(context)
        .exams
        .where((e) => e.date.isAfter(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final next = exams.isEmpty ? null : exams.first;

    return _HomeWidgetCard(
      title: _t('upcoming_exam'),
      icon: Icons.assignment_rounded,
      iconColor: Colors.red,
      children: next == null
          ? [_emptyLabel(context)]
          : [
              Text(
                next.subject.renamedTo ?? next.subject.name.escapeHtml().capital(),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d').format(next.date),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.of(context).text.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${next.date.difference(today).inDays} ${_t('days_until')}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.of(context).text.withOpacity(0.4),
                ),
              ),
            ],
    );
  }
}

// ─── 7. ExamListWidget ────────────────────────────────────────────────────────

class ExamListWidget extends StatelessWidget {
  const ExamListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exams = Provider.of<ExamProvider>(context)
        .exams
        .where((e) => e.date.isAfter(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final list = exams.take(5).toList();

    return _HomeWidgetCard(
      title: _t('exam_list'),
      icon: Icons.list_alt_rounded,
      iconColor: Colors.deepOrange,
      children: list.isEmpty
          ? [_emptyLabel(context)]
          : list.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.subject.renamedTo ?? e.subject.name.escapeHtml().capital(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      DateFormat('MM.dd').format(e.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).text.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

// ─── 8. UnreadMessagesWidget ──────────────────────────────────────────────────

class UnreadMessagesWidget extends StatelessWidget {
  const UnreadMessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final msgs = Provider.of<MessageProvider>(context).messages;
    final count = msgs
        .where((m) => !m.isSeen && m.type == MessageType.inbox)
        .length;

    return _HomeWidgetCard(
      title: _t('unread_messages'),
      icon: Icons.mail_rounded,
      iconColor: Colors.teal,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                '$count',
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w800),
              ),
              Text(
                _t('new_msgs'),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.of(context).text.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 9. RecentMessagesWidget ──────────────────────────────────────────────────

class RecentMessagesWidget extends StatelessWidget {
  const RecentMessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final msgs = Provider.of<MessageProvider>(context)
        .messages
        .where((m) => m.type == MessageType.inbox)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final list = msgs.take(3).toList();

    return _HomeWidgetCard(
      title: _t('recent_messages'),
      icon: Icons.inbox_rounded,
      iconColor: Colors.cyan,
      children: list.isEmpty
          ? [_emptyLabel(context)]
          : list.map((m) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.subject,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: m.isSeen
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('MM.dd').format(m.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).text.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

// ─── 10. AbsenceCountWidget ───────────────────────────────────────────────────

class AbsenceCountWidget extends StatelessWidget {
  const AbsenceCountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final absences = Provider.of<AbsenceProvider>(context).absences;
    final excused = absences.where((a) {
      final jName = a.justification?.name.toLowerCase() ?? '';
      return jName.contains('igazolt') && !jName.contains('igazolatlan');
    }).length;
    final unexcused = absences.length - excused;

    return _HomeWidgetCard(
      title: _t('absence_count'),
      icon: Icons.event_busy_rounded,
      iconColor: Colors.pinkAccent,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text('${_t('excused')}: $excused',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
            const SizedBox(width: 6),
            Text('${_t('unexcused')}: $unexcused',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

// ─── 11. RecentAbsencesWidget ─────────────────────────────────────────────────

class RecentAbsencesWidget extends StatelessWidget {
  const RecentAbsencesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final absences = Provider.of<AbsenceProvider>(context).absences.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final list = absences.take(5).toList();

    return _HomeWidgetCard(
      title: _t('recent_absences'),
      icon: Icons.person_off_rounded,
      iconColor: Colors.pink,
      children: list.isEmpty
          ? [_emptyLabel(context)]
          : list.map((a) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.subject.name.escapeHtml().capital(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      DateFormat('MM.dd').format(a.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).text.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

// ─── 12. TimetableTodayWidget ─────────────────────────────────────────────────

class TimetableTodayWidget extends StatelessWidget {
  const TimetableTodayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allLessons = Provider.of<TimetableProvider>(context)
            .getWeek(Week.fromDate(today)) ??
        [];
    final todayLessons = allLessons
        .where((l) {
          final d = DateTime(l.date.year, l.date.month, l.date.day);
          return d == today;
        })
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return _HomeWidgetCard(
      title: _t('timetable_today'),
      icon: Icons.today_rounded,
      iconColor: Colors.indigo,
      children: todayLessons.isEmpty
          ? [_emptyLabel(context)]
          : todayLessons.take(6).map((l) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        l.lessonIndex,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).text.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (l.room.isNotEmpty)
                      Text(
                        l.room,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.of(context).text.withOpacity(0.4),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

// ─── 13. NextLessonWidget ─────────────────────────────────────────────────────

class NextLessonWidget extends StatelessWidget {
  const NextLessonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allLessons = Provider.of<TimetableProvider>(context)
            .getWeek(Week.fromDate(today)) ??
        [];
    final upcoming = allLessons.where((l) {
      final d = DateTime(l.date.year, l.date.month, l.date.day);
      return d == today && l.start.isAfter(now);
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final next = upcoming.isEmpty ? null : upcoming.first;

    return _HomeWidgetCard(
      title: _t('next_lesson'),
      icon: Icons.schedule_rounded,
      iconColor: Colors.purple,
      children: next == null
          ? [Text(_t('no_more_lessons'),
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.of(context).text.withOpacity(0.5)))]
          : [
              Text(
                next.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(next.start),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.of(context).text.withOpacity(0.6),
                ),
              ),
              if (next.room.isNotEmpty)
                Text(
                  next.room,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.of(context).text.withOpacity(0.4),
                  ),
                ),
            ],
    );
  }
}

// ─── 14. HomeworkListWidget ───────────────────────────────────────────────────

class HomeworkListWidget extends StatelessWidget {
  const HomeworkListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hw = Provider.of<HomeworkProvider>(context)
        .homework
        .where((h) => h.deadline.isAfter(today))
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final list = hw.take(5).toList();

    return _HomeWidgetCard(
      title: _t('homework_list'),
      icon: Icons.edit_document,
      iconColor: Colors.green,
      children: list.isEmpty
          ? [_emptyLabel(context)]
          : list.map((h) {
              final subjectName = h.subject.renamedTo ??
                  h.subject.name.escapeHtml().capital();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        subjectName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      DateFormat('MM.dd').format(h.deadline),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).text.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

// ─── 15. NotesListWidget ──────────────────────────────────────────────────────

class NotesListWidget extends StatelessWidget {
  const NotesListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = Provider.of<NoteProvider>(context).notes.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final list = notes.take(3).toList();

    return _HomeWidgetCard(
      title: _t('notes_list'),
      icon: Icons.notes_rounded,
      iconColor: Colors.brown,
      children: list.isEmpty
          ? [_emptyLabel(context)]
          : list.map((n) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      DateFormat('MM.dd').format(n.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).text.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

// ─── 16. AttendanceRateWidget ─────────────────────────────────────────────────

class AttendanceRateWidget extends StatelessWidget {
  const AttendanceRateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final absences = Provider.of<AbsenceProvider>(context).absences;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allLessons = Provider.of<TimetableProvider>(context)
            .getWeek(Week.fromDate(today)) ??
        [];
    // estimate total lessons from timetable (multiply weekly count by ~36 weeks)
    final weeklyCount = allLessons.length;
    final totalEstimate = (weeklyCount * 36).clamp(1, 9999);
    final absenceCount = absences.length;
    final rate = ((totalEstimate - absenceCount) / totalEstimate).clamp(0.0, 1.0);

    return _HomeWidgetCard(
      title: _t('attendance_rate'),
      icon: Icons.how_to_reg_rounded,
      iconColor: Colors.tealAccent,
      children: [
        Center(
          child: Column(
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(rate * 100).toStringAsFixed(1)}%',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                _t('attendance_pct'),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.of(context).text.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 17. ExamCountdownWidget ──────────────────────────────────────────────────

class ExamCountdownWidget extends StatelessWidget {
  const ExamCountdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exams = Provider.of<ExamProvider>(context)
        .exams
        .where((e) => e.date.isAfter(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final next = exams.isEmpty ? null : exams.first;

    return _HomeWidgetCard(
      title: _t('exam_countdown'),
      icon: Icons.timer_rounded,
      iconColor: Colors.redAccent,
      children: next == null
          ? [Text(_t('no_upcoming_exams'),
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.of(context).text.withOpacity(0.5)))]
          : [
              Center(
                child: Column(
                  children: [
                    Text(
                      '${next.date.difference(today).inDays}',
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _t('days_until'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).text.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next.subject.renamedTo ?? next.subject.name.escapeHtml().capital(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
    );
  }
}

// ─── 18. WeeklyScheduleWidget ─────────────────────────────────────────────────

class WeeklyScheduleWidget extends StatelessWidget {
  const WeeklyScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final week = Week.current();
    final allLessons =
        Provider.of<TimetableProvider>(context).getWeek(week) ?? [];

    // Count lessons per weekday (1=Mon .. 5=Fri)
    final counts = <int, int>{};
    for (var l in allLessons) {
      final wd = l.date.weekday;
      if (wd <= 5) counts[wd] = (counts[wd] ?? 0) + 1;
    }

    final dayAbbrs = ['M', 'T', 'W', 'T', 'F'];

    return _HomeWidgetCard(
      title: _t('weekly_schedule'),
      icon: Icons.calendar_view_week_rounded,
      iconColor: Colors.blueGrey,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) {
            final wd = i + 1;
            final count = counts[wd] ?? 0;
            return Column(
              children: [
                Text(
                  dayAbbrs[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).text.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  _t('lesson_count'),
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.of(context).text.withOpacity(0.4),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ─── 19. GradeChartWidget ─────────────────────────────────────────────────────

class GradeChartWidget extends StatelessWidget {
  const GradeChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final grades = Provider.of<GradeProvider>(context)
        .grades
        .where((g) => g.type == GradeType.midYear && g.value.value > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final recent = grades.take(20).toList();

    final spots = List.generate(
      recent.length,
      (i) => FlSpot(i.toDouble(), recent[i].value.value.toDouble()),
    );

    return _HomeWidgetCard(
      title: _t('grade_chart'),
      icon: Icons.show_chart_rounded,
      iconColor: Colors.lightBlue,
      children: recent.isEmpty
          ? [_emptyLabel(context)]
          : [
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    minY: 1,
                    maxY: 5,
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
    );
  }
}

// ─── 20. QuickStatsWidget ─────────────────────────────────────────────────────

class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final grades = Provider.of<GradeProvider>(context).grades;
    final exams = Provider.of<ExamProvider>(context).exams;
    final absences = Provider.of<AbsenceProvider>(context).absences;
    final messages = Provider.of<MessageProvider>(context).messages;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalGrades = grades.where((g) => g.type == GradeType.midYear).length;
    final upcomingExams =
        exams.where((e) => e.date.isAfter(today)).length;
    final totalAbsences = absences.length;
    final unreadMsgs = messages
        .where((m) => !m.isSeen && m.type == MessageType.inbox)
        .length;

    Widget stat(String label, int value, IconData icon, Color color) {
      return Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.of(context).text.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return _HomeWidgetCard(
      title: _t('quick_stats'),
      icon: Icons.insights_rounded,
      iconColor: Colors.purpleAccent,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            stat(_t('grade_average'), totalGrades, Icons.star_rounded,
                Colors.amber),
            stat(_t('exam_list'), upcomingExams, Icons.assignment_rounded,
                Colors.red),
            stat(_t('absence_count'), totalAbsences,
                Icons.event_busy_rounded, Colors.pink),
            stat(_t('unread_messages'), unreadMsgs, Icons.mail_rounded,
                Colors.teal),
          ],
        ),
      ],
    );
  }
}

// ─── Renderer ─────────────────────────────────────────────────────────────────

Widget buildHomeWidget(HomeWidgetType type) {
  switch (type) {
    case HomeWidgetType.greeting:
      return const GreetingWidget();
    case HomeWidgetType.liveCard:
      return const LiveCardHomeWidget();
    case HomeWidgetType.gradeAverage:
      return const GradeAverageWidget();
    case HomeWidgetType.recentGrades:
      return const RecentGradesWidget();
    case HomeWidgetType.subjectAverages:
      return const SubjectAveragesWidget();
    case HomeWidgetType.upcomingExam:
      return const UpcomingExamWidget();
    case HomeWidgetType.examList:
      return const ExamListWidget();
    case HomeWidgetType.unreadMessages:
      return const UnreadMessagesWidget();
    case HomeWidgetType.recentMessages:
      return const RecentMessagesWidget();
    case HomeWidgetType.absenceCount:
      return const AbsenceCountWidget();
    case HomeWidgetType.recentAbsences:
      return const RecentAbsencesWidget();
    case HomeWidgetType.timetableToday:
      return const TimetableTodayWidget();
    case HomeWidgetType.nextLesson:
      return const NextLessonWidget();
    case HomeWidgetType.homeworkList:
      return const HomeworkListWidget();
    case HomeWidgetType.notesList:
      return const NotesListWidget();
    case HomeWidgetType.attendanceRate:
      return const AttendanceRateWidget();
    case HomeWidgetType.examCountdown:
      return const ExamCountdownWidget();
    case HomeWidgetType.weeklySchedule:
      return const WeeklyScheduleWidget();
    case HomeWidgetType.gradeChart:
      return const GradeChartWidget();
    case HomeWidgetType.quickStats:
      return const QuickStatsWidget();
  }
}
