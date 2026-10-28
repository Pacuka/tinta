import 'package:flutter/material.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/models/school_calendar.dart';
import 'package:folio_kreta_api/providers/school_calendar_provider.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/ink_stroke.dart';
import 'package:i18n_extension/i18n_extension.dart' show I18n;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'school_calendar.i18n.dart';

/// "Tanév rendje": breaks, days without lessons and other special days of
/// the school year, by month. The next day off is on top.
class SchoolCalendarPage extends StatefulWidget {
  const SchoolCalendarPage({super.key});

  @override
  State<SchoolCalendarPage> createState() => _SchoolCalendarPageState();
}

class _SchoolCalendarPageState extends State<SchoolCalendarPage> {
  bool _showPast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        Provider.of<SchoolCalendarProvider>(context, listen: false).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchoolCalendarProvider>(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0.0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18.0, color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    "school_calendar".i18n,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const InkStroke(style: InkStyle.drop),
          Expanded(
            child: RefreshIndicator(
              color: scheme.secondary,
              onRefresh: provider.fetch,
              child: _body(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, SchoolCalendarProvider provider) {
    final items = provider.items;
    if (provider.loading && items.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ]);
    }
    if (provider.error != null && items.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24.0), children: [
        const SizedBox(height: 60),
        Text("error".i18n,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16.0)),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
              onPressed: provider.fetch, child: Text("retry".i18n)),
        ),
      ]);
    }
    if (items.isEmpty) {
      return ListView(children: [Empty(subtitle: "empty".i18n)]);
    }

    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final past = items.where((i) => i.last.isBefore(today)).toList();
    final shown =
        _showPast ? items : items.where((i) => !i.last.isBefore(today)).toList();
    final locale = I18n.of(context).locale.toString();

    final children = <Widget>[
      _NextFreeCard(next: nextFreeItem(items, now), today: today),
      if (past.isNotEmpty)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _showPast = !_showPast),
            icon: Icon(_showPast
                ? Icons.expand_less_rounded
                : Icons.history_rounded),
            label: Text((_showPast ? "hide_past" : "show_past").i18n),
          ),
        ),
    ];

    String? month;
    for (final item in shown) {
      final m = DateFormat("yyyy MMMM", locale).format(item.first);
      if (m != month) {
        month = m;
        final title = DateFormat(
                item.first.year == now.year ? "MMMM" : "yyyy. MMMM", locale)
            .format(item.first);
        children.add(Padding(
          padding: const EdgeInsets.only(top: 18.0, bottom: 6.0, left: 4.0),
          child: Text(
            title[0].toUpperCase() + title.substring(1),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ));
      }
      children.add(_ItemTile(item, today: today, locale: locale));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
      children: children,
    );
  }
}

String _short(DateTime d, String locale) =>
    DateFormat("MMM d.", locale).format(d);

String _range(SchoolCalendarItem i, String locale) => i.isRange
    ? "${_short(i.first, locale)} – ${_short(i.last, locale)}"
    : _short(i.first, locale);

class _NextFreeCard extends StatelessWidget {
  const _NextFreeCard({required this.next, required this.today});

  final SchoolCalendarItem? next;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = I18n.of(context).locale.toString();
    final n = next;
    final on = scheme.onPrimaryContainer;

    String label;
    String when;
    double? progress;
    if (n == null) {
      label = "nothing_left".i18n;
      when = "";
    } else if (!n.first.isAfter(today)) {
      label = "now_free".i18n;
      final left = n.last.difference(today).inDays;
      when = left == 0 ? "last_day".i18n : "days_left".i18n.fill([left]);
      progress = (today.difference(n.first).inDays + 1) / n.length;
    } else {
      label = "next_free".i18n;
      final until = n.first.difference(today).inDays;
      when = until == 1 ? "tomorrow".i18n : "in_days".i18n.fill([until]);
    }

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 18.0),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: on.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0)),
          if (n != null) ...[
            const SizedBox(height: 4.0),
            Text(n.title,
                style: TextStyle(
                    color: on, fontSize: 22.0, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2.0),
            Text(
              "${_range(n, locale)}${n.isRange ? " · ${"days".i18n.fill([n.length])}" : ""}",
              style: TextStyle(color: on.withValues(alpha: 0.7), fontSize: 14.0),
            ),
            const SizedBox(height: 10.0),
            Text(when,
                style: TextStyle(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.0)),
            if (progress != null) ...[
              const SizedBox(height: 8.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5.0,
                  color: scheme.secondary,
                  backgroundColor: scheme.secondary.withValues(alpha: 0.15),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile(this.item, {required this.today, required this.locale});

  final SchoolCalendarItem item;
  final DateTime today;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = AppColors.of(context).text;
    final isPast = item.last.isBefore(today);
    final isNow = !item.first.isAfter(today) && !isPast;
    final accent = item.isFree ? scheme.secondary : text.withValues(alpha: 0.5);
    final weekday = DateFormat("EEE", locale).format(item.first);

    final sub = [
      if (item.isRange) _range(item, locale),
      if (item.isRange) "days".i18n.fill([item.length]),
      if (item.note != null) item.note!,
      if (item.isFree && !item.isRange) "no_school".i18n,
    ].join(" · ");

    return Opacity(
      opacity: isPast ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6.0),
        padding: const EdgeInsets.fromLTRB(12.0, 10.0, 14.0, 10.0),
        decoration: BoxDecoration(
          color: isNow ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            // Date block: day number + weekday of the first day
            SizedBox(
              width: 42.0,
              child: Column(
                children: [
                  Text("${item.first.day}",
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          height: 1.1)),
                  Text(weekday,
                      style: TextStyle(
                          fontSize: 12.0, color: text.withValues(alpha: 0.55))),
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.w700)),
                  if (sub.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(sub,
                          style: TextStyle(
                              fontSize: 13.0,
                              color: text.withValues(alpha: 0.6))),
                    ),
                ],
              ),
            ),
            if (item.isFree)
              Icon(Icons.beach_access_rounded, size: 20.0, color: accent),
          ],
        ),
      ),
    );
  }
}
