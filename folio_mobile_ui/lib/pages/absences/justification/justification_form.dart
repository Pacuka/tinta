import 'package:flutter/material.dart';
import 'package:folio_kreta_api/models/justification.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:provider/provider.dart';

import 'attachments.dart';
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
  final _mandatory = AttachmentController();
  final _others = AttachmentController();
  bool _sending = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _mandatory.addListener(_refresh);
    _others.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _reason.dispose();
    _mandatory.dispose();
    _others.dispose();
    super.dispose();
  }

  bool get _needsMandatory =>
      _type != null && mandatoryDocTypeId(_type!.code) != null;

  bool get _valid => canSubmit(
        rangeOk: isValidRange(_start, _end),
        type: _type,
        hasMandatory: _mandatory.uploaded.isNotEmpty,
        uploading: _mandatory.uploading || _others.uploading,
      );

  bool get _dirty =>
      _start != null ||
      _type != null ||
      _reason.text.trim().isNotEmpty ||
      _mandatory.items.isNotEmpty ||
      _others.items.isNotEmpty;

  Future<bool> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("leave_q".i18n),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("stay".i18n)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("leave".i18n)),
        ],
      ),
    );
    return ok == true;
  }

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
    if (_sending) return;
    setState(() => _sending = true);
    final reason = _reason.text.trim();
    final files = [
      ..._mandatory.uploaded.map((f) => "📎 ${f.name}"),
      ..._others.uploaded.map((f) => "📎 ${f.name}"),
    ];
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
          ...files,
          "",
          "no_edit_after".i18n,
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
    if (ok != true || !mounted) {
      if (mounted) setState(() => _sending = false);
      return;
    }

    final error = await Provider.of<CaseProvider>(context, listen: false)
        .submit(
            justificationType: _type!,
            start: _start!,
            end: _end!,
            reason: reason,
            mandatory: _needsMandatory && _mandatory.uploaded.isNotEmpty
                ? _mandatory.uploaded.first
                : null,
            others: _others.uploaded);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _done = true;
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

    return PopScope(
      canPop: _done || !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _sending) return;
        if (await _confirmLeave() && context.mounted) {
          _done = true;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
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
              if (_type != null) ...[
                const SizedBox(height: 16),
                if (_needsMandatory) ...[
                  AttachmentSection(
                    title: "mandatory_docs".i18n,
                    controller: _mandatory,
                    maxItems: 1,
                    enabled: !_sending,
                  ),
                  if (_mandatory.uploaded.isEmpty)
                    Text("mandatory_missing".i18n,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                ],
                AttachmentSection(
                  title: "other_docs".i18n,
                  controller: _others,
                  enabled: !_sending,
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _reason,
                onChanged: (_) => setState(() {}),
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
      ),
    );
  }
}
