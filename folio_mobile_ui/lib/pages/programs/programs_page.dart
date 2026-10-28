import 'package:flutter/material.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/models/program_event.dart';
import 'package:folio_kreta_api/providers/program_event_provider.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/ink_stroke.dart';
import 'package:i18n_extension/i18n_extension.dart' show I18n;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'programs.i18n.dart';

/// LÉP performances and NÉP programmes; parents allow or refuse them.
class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        Provider.of<ProgramEventProvider>(context, listen: false).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgramEventProvider>(context);
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
                    "programs".i18n,
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

  Widget _body(BuildContext context, ProgramEventProvider provider) {
    final events = provider.events;
    if (provider.loading && events.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ]);
    }
    if (provider.error != null && events.isEmpty) {
      return ListView(padding: const EdgeInsets.all(24.0), children: [
        const SizedBox(height: 60),
        Text("error".i18n,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0)),
        const SizedBox(height: 16),
        Center(
          child: TextButton(onPressed: provider.fetch, child: Text("retry".i18n)),
        ),
      ]);
    }
    if (events.isEmpty) {
      return ListView(children: [Empty(subtitle: "empty".i18n)]);
    }

    final now = DateTime.now();
    final upcoming = events.where((e) => e.end.isAfter(now)).toList().reversed;
    final earlier = events.where((e) => !e.end.isAfter(now));
    final pending = provider.pendingCount(now);
    final scheme = Theme.of(context).colorScheme;

    Widget header(String t) => Padding(
          padding: const EdgeInsets.only(top: 18.0, bottom: 6.0, left: 4.0),
          child: Text(t,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.6))),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
      children: [
        if (pending > 0)
          Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(children: [
              Icon(Icons.how_to_reg_rounded, color: scheme.secondary),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text("pending_n".i18n.fill([pending]),
                    style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.0)),
              ),
            ]),
          ),
        if (upcoming.isNotEmpty) header("upcoming".i18n),
        for (final e in upcoming) _ProgramTile(e),
        if (earlier.isNotEmpty) header("earlier".i18n),
        for (final e in earlier) _ProgramTile(e),
      ],
    );
  }
}

String _when(ProgramEvent e, String locale) {
  final day = DateFormat("MMM d., EEEE", locale).format(e.start);
  final from = DateFormat("H:mm").format(e.start);
  final to = DateFormat("H:mm").format(e.end);
  return e.end.isAfter(e.start) ? "$day $from–$to" : "$day $from";
}

/// Status with an icon, so it doesn't rely on colour alone.
(IconData, String, Color) _status(BuildContext context, ProgramEvent e) {
  final colors = AppColors.of(context);
  final past = !e.end.isAfter(DateTime.now());
  if (past && e.appeared) {
    return (Icons.check_circle_rounded, "appeared".i18n, colors.green);
  }
  if (e.permitted == true) {
    return (Icons.check_rounded, "allowed".i18n, colors.green);
  }
  if (e.permitted == false) return (Icons.block_rounded, "refused".i18n, colors.red);
  if (past || !e.canDecide(DateTime.now())) {
    return (Icons.remove_rounded, "no_decision".i18n, colors.text.withValues(alpha: 0.5));
  }
  return (Icons.schedule_rounded, "waiting".i18n, colors.orange);
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile(this.event);

  final ProgramEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = AppColors.of(context).text;
    final locale = I18n.of(context).locale.toString();
    final (icon, label, color) = _status(context, event);
    final past = !event.end.isAfter(DateTime.now());
    final sub = [event.organizer, event.place].where((s) => s.isNotEmpty).join(" · ");

    return Opacity(
      opacity: past ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showProgramSheet(context, event),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: scheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(event.kind == ProgramKind.lep ? "LÉP" : "NÉP",
                          style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w800,
                              color: scheme.secondary)),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(_when(event, locale),
                          style: TextStyle(
                              fontSize: 13.0, color: text.withValues(alpha: 0.6))),
                    ),
                  ]),
                  const SizedBox(height: 6.0),
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.w700)),
                  if (sub.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(sub,
                          style: TextStyle(
                              fontSize: 13.0, color: text.withValues(alpha: 0.6))),
                    ),
                  const SizedBox(height: 8.0),
                  Row(children: [
                    Icon(icon, size: 16.0, color: color),
                    const SizedBox(width: 6.0),
                    Text(label,
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showProgramSheet(BuildContext context, ProgramEvent event) {
  showRoundedModalBottomSheet(
    context,
    child: _ProgramSheet(event),
  );
}

class _ProgramSheet extends StatefulWidget {
  const _ProgramSheet(this.event);

  final ProgramEvent event;

  @override
  State<_ProgramSheet> createState() => _ProgramSheetState();
}

class _ProgramSheetState extends State<_ProgramSheet> {
  bool _sending = false;

  Future<void> _decide(bool allow) async {
    setState(() => _sending = true);
    final provider = Provider.of<ProgramEventProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.decide(widget.event, allow);
    if (!mounted) return;
    setState(() => _sending = false);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? (allow ? "saved_allow" : "saved_refuse").i18n),
    ));
    if (error == null) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgramEventProvider>(context);
    // the list may have the newer decision
    final e = provider.events.firstWhere(
        (x) => x.kind == widget.event.kind && x.id == widget.event.id,
        orElse: () => widget.event);
    final scheme = Theme.of(context).colorScheme;
    final text = AppColors.of(context).text;
    final locale = I18n.of(context).locale.toString();
    final (icon, label, color) = _status(context, e);
    final now = DateTime.now();
    final blocked = provider.isParent ? provider.blockReason(e, now) : null;
    final child =
        Provider.of<UserProvider>(context, listen: false).user?.name ?? "";

    Widget row(String k, String v) => v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text("$k: $v",
                style: TextStyle(fontSize: 14.0, color: text.withValues(alpha: 0.75))),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.title,
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4.0),
          Text(_when(e, locale),
              style: TextStyle(fontSize: 14.0, color: text.withValues(alpha: 0.7))),
          row("organizer".i18n, e.organizer),
          row("place".i18n, e.place),
          const SizedBox(height: 12.0),
          Row(children: [
            Icon(icon, size: 18.0, color: color),
            const SizedBox(width: 6.0),
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ]),
          if (provider.isParent) ...[
            const SizedBox(height: 16.0),
            if (blocked != null)
              Text(blocked,
                  style: TextStyle(color: text.withValues(alpha: 0.7)))
            else ...[
              Text("question".i18n.fill([child]),
                  style: const TextStyle(
                      fontSize: 16.0, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4.0),
              Text("change_hint".i18n,
                  style: TextStyle(fontSize: 13.0, color: text.withValues(alpha: 0.6))),
              const SizedBox(height: 14.0),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sending || e.permitted == false
                        ? null
                        : () => _decide(false),
                    child: Text("refuse".i18n),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: scheme.secondary,
                        foregroundColor: scheme.onSecondary),
                    onPressed: _sending || e.permitted == true
                        ? null
                        : () => _decide(true),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text("allow".i18n),
                  ),
                ),
              ]),
            ],
          ],
        ],
      ),
    );
  }
}
