import 'package:flutter/material.dart';
import 'package:folio_kreta_api/models/consulting_hour.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:folio_kreta_api/providers/consulting_provider.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/pages/consulting/ics.dart';
import 'package:i18n_extension/i18n_extension.dart' show I18n;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'consulting.i18n.dart';

String _hm(DateTime d) => DateFormat("HH:mm").format(d);

String consultingStateLabel(ConsultingHour hour, DateTime now) {
  switch (hour.state(now)) {
    case ConsultingState.booked:
      return "state_booked".i18n.fill([_hm(hour.myBooking!.start)]);
    case ConsultingState.noSignup:
      return "state_no_signup".i18n;
    case ConsultingState.closed:
      return "state_closed".i18n;
    case ConsultingState.full:
      return "state_full".i18n;
    case ConsultingState.open:
      return "state_open".i18n;
  }
}

/// Only while signing up is still possible.
String? deadlineHint(ConsultingHour hour, DateTime now) {
  final deadline = hour.deadline;
  if (deadline == null || hour.state(now) != ConsultingState.open) {
    return null;
  }
  final days = DateUtils.dateOnly(deadline)
      .difference(DateUtils.dateOnly(now))
      .inDays;
  if (days <= 0) return "hint_today".i18n;
  return "hint_days".i18n.fill([days]);
}

String consultingDay(DateTime d) => I18n.locale.languageCode == "hu"
    ? DateFormat("MMMM d., EEEE", "hu_HU").format(d)
    : DateFormat("EEEE, MMMM d", I18n.locale.toString()).format(d);

/// The provider's (Hungarian) messages in the app's language.
String consultingErrorText(String error) {
  const keys = {
    consultingTakenMessage: "err_taken",
    consultingAlreadyMessage: "err_already",
    consultingFailedMessage: "err_failed",
    uncertainSubmitMessage: "err_uncertain",
    networkErrorMessage: "err_network",
  };
  return keys[error]?.i18n ?? error;
}

/// Details + booking / cancelling, wired to [ConsultingProvider].
Future<void> showConsultingSheet(BuildContext context, ConsultingHour hour) {
  final provider = Provider.of<ConsultingProvider>(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  void report(String? error, String ok) {
    messenger.showSnackBar(SnackBar(
        content: Text(error != null ? consultingErrorText(error) : ok)));
  }

  return showRoundedModalBottomSheet(
    context,
    child: ConsultingSheet(
      hour: hour,
      onBook: (slot) async {
        final error = await provider.book(slot, hour);
        report(error, "booked_ok".i18n);
        return error;
      },
      onCancel: (slot) async {
        final error = await provider.cancel(slot, hour);
        report(error, "cancelled_ok".i18n);
        return error;
      },
    ),
  );
}

class ConsultingSheet extends StatefulWidget {
  const ConsultingSheet({
    super.key,
    required this.hour,
    required this.onBook,
    required this.onCancel,
  });

  final ConsultingHour hour;

  /// null = OK, otherwise the error already shown to the user.
  final Future<String?> Function(ConsultingSlot slot) onBook;
  final Future<String?> Function(ConsultingSlot slot) onCancel;

  @override
  State<ConsultingSheet> createState() => _ConsultingSheetState();
}

class _ConsultingSheetState extends State<ConsultingSheet> {
  ConsultingSlot? _selected;
  bool _busy = false;

  ConsultingHour get hour => widget.hour;

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("no".i18n),
          ),
          TextButton(
            key: const Key("consulting-confirm"),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("yes".i18n),
          ),
        ],
      ),
    );
    return ok == true;
  }

  String _slotText(ConsultingSlot s) =>
      "${hour.teacherName}\n${consultingDay(s.start)}, ${_hm(s.start)}–${_hm(s.end)}"
      "${hour.room.isNotEmpty ? " · ${hour.room}" : ""}";

  /// Always closes afterwards: the hour shown here may be stale now (the
  /// provider re-fetched), so a retry must start from the fresh list.
  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).maybePop();
      }
    }
  }

  Future<void> _book() async {
    final slot = _selected;
    if (slot == null || _busy) return;
    _busy = true; // block a second tap before the dialog is up
    final ok = await _confirm(
        "confirm_book".i18n, _slotText(slot));
    _busy = false;
    if (!ok || !mounted) return;
    await _run(() => widget.onBook(slot));
  }

  Future<void> _cancel(ConsultingSlot slot) async {
    if (_busy) return;
    final late = (hour.deadline ?? hour.end).isBefore(DateTime.now());
    _busy = true;
    final ok = await _confirm(
        "confirm_cancel".i18n,
        _slotText(slot) +
            (late
                ? "\n\n${"late_cancel".i18n}"
                : ""));
    _busy = false;
    if (!ok || !mounted) return;
    await _run(() => widget.onCancel(slot));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final state = hour.state(now);
    final mine = hour.myBooking;
    final hint = deadlineHint(hour, now);
    final muted = TextStyle(color: scheme.onSurface.withValues(alpha: 0.7));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hour.teacherName,
              style:
                  const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              "${consultingDay(hour.start)}, ${_hm(hour.start)}–${_hm(hour.end)}",
              style: muted),
          if (hour.room.isNotEmpty)
            Text("room".i18n.fill([hour.room]), style: muted),
          if (hour.deadline != null && hour.signupEnabled)
            Text(
                "deadline".i18n.fill([
                  "${consultingDay(hour.deadline!)}, ${_hm(hour.deadline!)}"
                ]),
                style: muted),
          const SizedBox(height: 12),
          _StateChip(text: consultingStateLabel(hour, now), state: state),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint,
                style: TextStyle(
                    color: scheme.secondary, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          if (mine != null) ...[
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key("consulting-calendar"),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!await shareIcs(hour, mine)) {
                      messenger.showSnackBar(SnackBar(
                          content: Text("calendar_failed".i18n)));
                    }
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: Text("calendar".i18n),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key("consulting-cancel"),
                  onPressed: _busy ? null : () => _cancel(mine),
                  icon: const Icon(Icons.close_rounded),
                  label: Text("cancel_booking".i18n),
                ),
              ),
            ]),
          ] else if (state == ConsultingState.open) ...[
            Text("pick_slot".i18n,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in hour.freeSlotsAt(now))
                  ChoiceChip(
                    key: Key("consulting-slot-${s.id}"),
                    label: Text(_hm(s.start)),
                    selected: _selected?.id == s.id,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _selected = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key("consulting-book"),
                onPressed: _selected == null || _busy ? null : _book,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text("book".i18n),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.text, required this.state});

  final String text;
  final ConsultingState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (state) {
      ConsultingState.booked => scheme.primary,
      ConsultingState.open => scheme.secondary,
      _ => scheme.onSurface.withValues(alpha: 0.6),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12.0, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Public so the page can reuse the same chip.
Widget consultingStateChip(ConsultingHour hour, DateTime now) =>
    _StateChip(text: consultingStateLabel(hour, now), state: hour.state(now));
