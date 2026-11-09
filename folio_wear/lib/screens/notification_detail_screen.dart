import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/wear_notification.dart';
import '../providers/wear_data_provider.dart';
import '../theme/wear_theme.dart';
import '../widgets/edge_fade.dart';
import '../widgets/wear_curved_scrollbar.dart';
import 'wear_shell.dart';

const notificationTypeColor = {
  'grade': Color(0xFFFFCC80),
  'absence': Color(0xFFEF9A9A),
  'message': Color(0xFF90CAF9),
  'note': Color(0xFFCE93D8),
  'exam': Color(0xFFFFAB91),
  'homework': Color(0xFFA5D6A7),
};

const notificationTypeIcon = {
  'grade': Icons.grade_rounded,
  'absence': Icons.event_busy_rounded,
  'message': Icons.mail_rounded,
  'note': Icons.sticky_note_2_rounded,
  'exam': Icons.quiz_rounded,
  'homework': Icons.assignment_rounded,
};

/// The 1-5 mark of a grade notification, or null.
int? notificationGrade(WearNotification item) {
  final v = item.gradeValue;
  if (v != null && v >= 1 && v <= 5) return v;
  if (item.type != 'grade') return null;
  final n = int.tryParse(item.body.split('–').last.trim());
  return (n != null && n >= 1 && n <= 5) ? n : null;
}

/// One notification in full: opened by tapping it in the list. Swipe right,
/// the back button or the system back closes it; the crown scrolls.
class NotificationDetailScreen extends StatefulWidget {
  final WearNotification item;
  /// Put before the date, e.g. "Határidő: " for homework.
  final String datePrefix;
  const NotificationDetailScreen(
      {super.key, required this.item, this.datePrefix = ''});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final _scroll = ScrollController();
  void Function(double)? _previousRotary;
  double? _crownTarget;

  @override
  void initState() {
    super.initState();
    _previousRotary = WearDataProvider.onRotaryInput;
    WearDataProvider.onRotaryInput = _handleRotary;
  }

  @override
  void dispose() {
    WearDataProvider.onRotaryInput = _previousRotary;
    _scroll.dispose();
    super.dispose();
  }

  void _handleRotary(double delta) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final target = ((_crownTarget ?? pos.pixels) +
            delta * WearShellTuning.crownStep)
        .clamp(0.0, pos.maxScrollExtent);
    _crownTarget = target;
    _scroll
        .animateTo(target,
            duration: WearShellTuning.crownGlide, curve: Curves.easeOut)
        .whenComplete(() {
      if (_crownTarget == target) _crownTarget = null;
    });
  }

  void _close() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = notificationTypeColor[item.type] ?? Colors.white70;
    final icon = notificationTypeIcon[item.type] ?? Icons.notifications_rounded;
    final grade = notificationGrade(item);
    final t = item.timestamp;
    final hasTime = t.hour != 0 || t.minute != 0;
    final date = DateFormat(hasTime ? 'yyyy. MM. dd. HH:mm' : 'yyyy. MM. dd.')
        .format(t);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 300) _close();
        },
        child: WearCurvedScrollbar(
          controller: _scroll,
          child: ListView(
            controller: _scroll,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(26.0, 26.0, 26.0, 48.0),
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: grade != null
                        ? WearColors.cobalt
                        : color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: grade != null
                      ? Center(
                          child: Text('$grade',
                              style: const TextStyle(
                                fontSize: 19.0,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              )),
                        )
                      : Icon(icon, size: 19.0, color: color),
                ),
              ),
              const SizedBox(height: 8.0),
              EdgeFade(
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 3.0),
              Text(
                '${widget.datePrefix}$date',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10.5,
                ),
              ),
              // A note's body is its text: shown once, below.
              if (item.body.isNotEmpty && item.body != item.text &&
                  item.type != 'note') ...[
                const SizedBox(height: 8.0),
                EdgeFade(
                  child: Text(
                    item.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: item.type == 'grade'
                          ? color
                          : Colors.white.withValues(alpha: 0.75),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
              if (item.lines.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                for (final line in item.lines)
                  EdgeFade(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: WearColors.muted,
                          fontSize: 12.0,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
              if (_longText(item).isNotEmpty) ...[
                const SizedBox(height: 10.0),
                EdgeFade(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: WearColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      _longText(item),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// A note's text comes as body from phones older than 1.6.2.
  static String _longText(WearNotification item) {
    if (item.text.isNotEmpty) return item.text;
    return item.type == 'note' ? item.body : '';
  }
}
