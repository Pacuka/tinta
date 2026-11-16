// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:folio/models/home_layout.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:provider/provider.dart';

import 'home_widgets.i18n.dart';
import 'package:folio_mobile_ui/common/tinta_switch.dart';

class HomeEditScreen extends StatefulWidget {
  const HomeEditScreen({super.key});

  @override
  State<HomeEditScreen> createState() => _HomeEditScreenState();
}

class _HomeEditScreenState extends State<HomeEditScreen> {
  late List<HomeWidgetItem> _items;

  @override
  void initState() {
    super.initState();
    final layout =
        Provider.of<SettingsProvider>(context, listen: false).homeLayout;
    // deep copy
    _items = layout.items
        .map((e) => HomeWidgetItem(
              type: e.type,
              size: e.size,
              enabled: e.enabled,
            ))
        .toList();
  }

  void _save() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.update(homeLayoutJson: HomeLayout(items: _items).toJson());
    Navigator.of(context).pop();
  }

  String _widgetTitle(HomeWidgetType type) => type.name.i18n;

  IconData _widgetIcon(HomeWidgetType type) {
    switch (type) {
      case HomeWidgetType.greeting:
        return Icons.waving_hand_rounded;
      case HomeWidgetType.liveCard:
        return Icons.live_tv_rounded;
      case HomeWidgetType.gradeAverage:
        return Icons.star_rounded;
      case HomeWidgetType.recentGrades:
        return Icons.grade_rounded;
      case HomeWidgetType.subjectAverages:
        return Icons.bar_chart_rounded;
      case HomeWidgetType.upcomingExam:
        return Icons.assignment_rounded;
      case HomeWidgetType.examList:
        return Icons.list_alt_rounded;
      case HomeWidgetType.unreadMessages:
        return Icons.mail_rounded;
      case HomeWidgetType.recentMessages:
        return Icons.inbox_rounded;
      case HomeWidgetType.absenceCount:
        return Icons.event_busy_rounded;
      case HomeWidgetType.recentAbsences:
        return Icons.person_off_rounded;
      case HomeWidgetType.timetableToday:
        return Icons.today_rounded;
      case HomeWidgetType.nextLesson:
        return Icons.schedule_rounded;
      case HomeWidgetType.homeworkList:
        return Icons.edit_document;
      case HomeWidgetType.notesList:
        return Icons.notes_rounded;
      case HomeWidgetType.attendanceRate:
        return Icons.how_to_reg_rounded;
      case HomeWidgetType.examCountdown:
        return Icons.timer_rounded;
      case HomeWidgetType.weeklySchedule:
        return Icons.calendar_view_week_rounded;
      case HomeWidgetType.gradeChart:
        return Icons.show_chart_rounded;
      case HomeWidgetType.quickStats:
        return Icons.insights_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_home'.i18n),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('done'.i18n,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        itemCount: _items.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          return _EditTile(
            key: ValueKey(item.type),
            index: index,
            item: item,
            icon: _widgetIcon(item.type),
            title: _widgetTitle(item.type),
            onToggleEnabled: (val) {
              setState(() => item.enabled = val);
            },
            onToggleSize: () {
              setState(() {
                item.size = item.size == HomeWidgetSize.full
                    ? HomeWidgetSize.half
                    : HomeWidgetSize.full;
              });
            },
          );
        },
      ),
    );
  }
}

class _EditTile extends StatelessWidget {
  const _EditTile({
    super.key,
    required this.index,
    required this.item,
    required this.icon,
    required this.title,
    required this.onToggleEnabled,
    required this.onToggleSize,
  });

  final int index;
  final HomeWidgetItem item;
  final IconData icon;
  final String title;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onToggleSize;

  @override
  Widget build(BuildContext context) {
    final disabled = !item.enabled;
    final cs = Theme.of(context).colorScheme;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: ListTile(
        leading: Icon(icon,
            color: disabled
                ? AppColors.of(context).text.withOpacity(0.4)
                : cs.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: disabled
                ? AppColors.of(context).text.withOpacity(0.5)
                : null,
          ),
        ),
        subtitle: GestureDetector(
          onTap: onToggleSize,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.size == HomeWidgetSize.full
                      ? Icons.crop_landscape_rounded
                      : Icons.crop_rounded,
                  size: 14,
                  color: AppColors.of(context).text.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  item.size == HomeWidgetSize.full
                      ? 'full_width'.i18n
                      : 'half_width'.i18n,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.of(context).text.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TintaSwitch(
              value: item.enabled,
              onChanged: onToggleEnabled,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
