import 'package:flutter/material.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_kreta_api/providers/consulting_provider.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/ink_stroke.dart';
import 'package:folio_mobile_ui/pages/consulting/consulting_sheet.dart';
import 'package:intl/intl.dart';

import 'consulting.i18n.dart';
import 'package:provider/provider.dart';

/// Teacher consultation hours: own bookings on top, then every hour by day.
class ConsultingPage extends StatefulWidget {
  const ConsultingPage({super.key});

  @override
  State<ConsultingPage> createState() => _ConsultingPageState();
}

class _ConsultingPageState extends State<ConsultingPage> {
  String _query = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Provider.of<ConsultingProvider>(context, listen: false).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ConsultingProvider>(context);
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
                    "consulting".i18n,
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

  Widget _body(BuildContext context, ConsultingProvider provider) {
    final hours = provider.hours;
    if (provider.loading && hours.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ]);
    }
    if (provider.error != null && hours.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24.0), children: [
        const SizedBox(height: 60),
        Text(consultingErrorText(provider.error!),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16.0)),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
              onPressed: provider.fetch, child: Text("retry".i18n)),
        ),
      ]);
    }
    if (hours.isEmpty) {
      return ListView(children: [Empty(subtitle: "empty".i18n)]);
    }

    final now = DateTime.now();
    final teachers = hours.map((h) => h.teacherId).toSet();
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? hours
        : hours.where((h) => h.teacherName.toLowerCase().contains(q)).toList();
    final mine = hours
        .where((h) => h.myBooking != null && h.end.isAfter(now))
        .toList();

    final children = <Widget>[
      if (mine.isNotEmpty) _MyBookings(mine),
      if (teachers.length > 5)
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "search".i18n,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
    ];
    DateTime? day;
    for (final h in shown) {
      final d = DateUtils.dateOnly(h.start);
      if (d != day) {
        day = d;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 18.0, bottom: 4.0, left: 4.0),
          child: Text(_dayTitle(d, now),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
        ));
      }
      children.add(_HourTile(h));
    }
    if (shown.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text("no_match".i18n, textAlign: TextAlign.center),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
      children: children,
    );
  }
}

String _dayTitle(DateTime day, DateTime now) {
  final today = DateUtils.dateOnly(now);
  final diff = day.difference(today).inDays;
  if (diff == 0) return "today".i18n;
  if (diff == 1) return "tomorrow".i18n;
  final s = consultingDay(day);
  return s[0].toUpperCase() + s.substring(1);
}

String _hm(DateTime d) => DateFormat("HH:mm").format(d);

class _MyBookings extends StatelessWidget {
  const _MyBookings(this.hours);

  final List<ConsultingHour> hours;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("my_bookings".i18n,
              style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.0)),
          for (final h in hours)
            InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () => showConsultingSheet(context, h),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(children: [
                  Icon(Icons.event_available_rounded,
                      color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.teacherName,
                            style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700)),
                        Text(
                            "${_dayTitle(DateUtils.dateOnly(h.myBooking!.start), DateTime.now())}, "
                            "${_hm(h.myBooking!.start)}–${_hm(h.myBooking!.end)}"
                            "${h.room.isNotEmpty ? " · ${h.room}" : ""}",
                            style: TextStyle(
                                color: scheme.onPrimaryContainer
                                    .withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _HourTile extends StatelessWidget {
  const _HourTile(this.hour);

  final ConsultingHour hour;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final hint = deadlineHint(hour, now);
    final muted = TextStyle(color: scheme.onSurface.withValues(alpha: 0.7));
    return GestureDetector(
      onTap: () => showConsultingSheet(context, hour),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hour.teacherName,
                style: const TextStyle(
                    fontSize: 16.0, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
                "${_hm(hour.start)}–${_hm(hour.end)}"
                "${hour.room.isNotEmpty ? " · ${hour.room}" : ""}",
                style: muted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                consultingStateChip(hour, now),
                if (hint != null)
                  Text(hint,
                      style: TextStyle(
                          fontSize: 12.0,
                          color: scheme.secondary,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
