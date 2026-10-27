import 'package:flutter/material.dart';
import 'package:folio_kreta_api/models/justification.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:provider/provider.dart';

import 'justification.i18n.dart';
import 'justifications_page.dart' show formatRange;

/// New absence justification. Pops `true` once KRÉTA accepted it.
class JustificationForm extends StatefulWidget {
  const JustificationForm({super.key});

  @override
  State<JustificationForm> createState() => _JustificationFormState();
}

class _JustificationFormState extends State<JustificationForm> {
  DateTime? _start;
  DateTime? _end;
  KretaType? _type;
  final _reason = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _valid => _type != null && isValidRange(_start, _end);

  Future<void> _pick(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? _start ?? now,
      // Same window as the official app's picker.
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      locale: const Locale("hu", "HU"),
      helpText: "pick_date".i18n,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        _end ??= picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _send() async {
    final reason = _reason.text.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("confirm_title".i18n),
        content: Text([
          "confirm_body".i18n,
          "",
          _type!.name,
          formatRange(_start, _end),
          if (reason.isNotEmpty) "„$reason”",
        ].join("\n")),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("cancel".i18n)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("confirm_send".i18n)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _sending = true);
    final error = await Provider.of<CaseProvider>(context, listen: false)
        .submit(
            justificationType: _type!,
            start: _start!,
            end: _end!,
            reason: reason);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = Provider.of<CaseProvider>(context).justificationTypes;
    final badRange =
        _start != null && _end != null && !isValidRange(_start, _end);

    Widget dateField(String label, DateTime? value, bool isStart) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: _sending ? null : () => _pick(isStart),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.event_rounded),
              ),
              child: Text(value == null ? "" : formatRange(value, value)),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text("new_justification".i18n)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            Row(children: [
              dateField("from".i18n, _start, true),
              const SizedBox(width: 12),
              dateField("to".i18n, _end, false),
            ]),
            if (badRange)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("bad_range".i18n,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<KretaType>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "type".i18n,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final t in types)
                  DropdownMenuItem(value: t, child: Text(t.name)),
              ],
              onChanged: _sending ? null : (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reason,
              enabled: !_sending,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: "reason".i18n,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _valid && !_sending ? _send : null,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text("send".i18n),
            ),
          ],
        ),
      ),
    );
  }
}
