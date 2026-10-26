import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/wear_notification.dart';
import '../providers/wear_data_provider.dart';
import '../widgets/wear_curved_scrollbar.dart';

const _kCardBg = Color(0xFF1C1C1E);
// Round screen: keep content away from the curved edge.
const _kHPad = 22.0;
const _kRadius = 16.0;
const _kItemSpacing = 4.0;

class NotificationsScreen extends StatelessWidget {
  final ScrollController scrollController;
  const NotificationsScreen({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Consumer<WearDataProvider>(builder: (context, data, _) {
        final items = data.notifications;
        return items.isEmpty
            ? _EmptyState(data: data)
            : _NotifList(items: items, scrollController: scrollController);
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
              child: Icon(Icons.notifications_none_rounded,
                  size: 28.0, color: cs.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Nincs értesítés',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600),
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

class _NotifList extends StatelessWidget {
  final List<WearNotification> items;
  final ScrollController scrollController;
  const _NotifList({required this.items, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return WearCurvedScrollbar(
      controller: scrollController,
      child: CustomScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
                top: 30.0, left: 28.0, right: 28.0, bottom: 8.0),
            sliver: const SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Értesítések',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: _kItemSpacing),
                child: _NotifTile(item: items[i]),
              ),
              childCount: items.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 52.0)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final WearNotification item;
  const _NotifTile({required this.item});

  int? get _gradeNum {
    if (item.gradeValue != null && item.gradeValue! >= 1 && item.gradeValue! <= 5) {
      return item.gradeValue;
    }
    if (item.type != 'grade') return null;
    final last = item.body.split('–').last.trim();
    final n = int.tryParse(last);
    return (n != null && n >= 1 && n <= 5) ? n : null;
  }

  static const _typeColor = {
    'grade':    Color(0xFFFFCC80),
    'absence':  Color(0xFFEF9A9A),
    'message':  Color(0xFF90CAF9),
    'note':     Color(0xFFCE93D8),
    'exam':     Color(0xFFFFAB91),
    'homework': Color(0xFFA5D6A7),
  };

  static const _typeIcon = {
    'grade':    Icons.grade_rounded,
    'absence':  Icons.event_busy_rounded,
    'message':  Icons.mail_rounded,
    'note':     Icons.sticky_note_2_rounded,
    'exam':     Icons.quiz_rounded,
    'homework': Icons.assignment_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColor[item.type] ?? Colors.white70;
    final icon  = _typeIcon[item.type]  ?? Icons.notifications_rounded;
    final gradeNum = _gradeNum;
    final isGrade  = item.type == 'grade';
    final timeStr  = DateFormat('MM.dd HH:mm').format(item.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: Container(
        decoration: BoxDecoration(
          color: isGrade ? color.withValues(alpha: 0.1) : _kCardBg,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading icon / grade badge
            Container(
              width: 34.0,
              height: 34.0,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(11.0),
              ),
              child: gradeNum != null
                  ? Center(
                      child: Text(
                        '$gradeNum',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1.0,
                        ),
                      ),
                    )
                  : Icon(icon, size: 16.0, color: color),
            ),
            const SizedBox(width: 10.0),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 8.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: isGrade
                            ? color.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.46),
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
