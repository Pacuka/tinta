import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/wear_notification.dart';
import '../providers/wear_data_provider.dart';
import '../theme/wear_theme.dart';
import '../widgets/edge_fade.dart';
import '../widgets/page_title.dart';
import '../widgets/wear_curved_scrollbar.dart';
import 'notification_detail_screen.dart';

const _kCardBg = WearColors.surface;
// Round screen: keep content away from the curved edge.
const _kHPad = 22.0;
const _kRadius = 20.0;
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
            : _NotifList(
                items: items,
                average: data.extras?.average,
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
                color: WearColors.surface,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  size: 28.0, color: WearColors.ink.withValues(alpha: 0.7)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 22.0, vertical: 9.0),
                decoration: BoxDecoration(
                  color: WearColors.ink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Text(
                  'Frissítés',
                  style: TextStyle(
                      color: WearColors.ink,
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
  final double? average;
  final ScrollController scrollController;
  const _NotifList({
    required this.items,
    required this.average,
    required this.scrollController,
  });

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
            sliver: const SliverToBoxAdapter(child: PageTitle('Értesítések')),
          ),
          if (average != null)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 8.0),
              sliver: SliverToBoxAdapter(
                child: EdgeFade(
                  child: Text(
                    'Tanulmányi átlag: ${average!.toStringAsFixed(2).replaceAll('.', ',')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WearColors.inkLight,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: _kItemSpacing),
                child: EdgeFade(child: _NotifTile(item: items[i])),
              ),
              childCount: items.length,
              addRepaintBoundaries: false,
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

  @override
  Widget build(BuildContext context) {
    final color = notificationTypeColor[item.type] ?? Colors.white70;
    final icon = notificationTypeIcon[item.type] ?? Icons.notifications_rounded;
    final gradeNum = notificationGrade(item);
    final isGrade = item.type == 'grade';
    final now = DateTime.now();
    final isToday = item.timestamp.year == now.year &&
        item.timestamp.month == now.month &&
        item.timestamp.day == now.day;
    final timeStr =
        DateFormat(isToday ? 'HH:mm' : 'MM.dd.').format(item.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => NotificationDetailScreen(item: item),
          ));
        },
        child: Container(
          decoration: BoxDecoration(
            color: _kCardBg,
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
                  color: gradeNum != null
                      ? WearColors.cobalt
                      : color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: gradeNum != null
                    ? Center(
                        child: Text(
                          '$gradeNum',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
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
      ),
    );
  }
}
