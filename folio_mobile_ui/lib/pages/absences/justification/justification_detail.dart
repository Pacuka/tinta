import 'package:flutter/material.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/models/justification.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import 'attachments.dart';
import 'justification.i18n.dart';
import 'justifications_page.dart' show formatRange;

/// One justification: state, documents, decisions, and the "hiánypótlás"
/// (missing document) reply when the school asks for it.
class JustificationDetailPage extends StatefulWidget {
  const JustificationDetailPage({super.key, required this.caseId});

  final String caseId;

  @override
  State<JustificationDetailPage> createState() =>
      _JustificationDetailPageState();
}

class _JustificationDetailPageState extends State<JustificationDetailPage> {
  CaseDetail? _detail;
  bool _loading = true;
  final Map<int, String> _signers = {};

  CaseProvider get _cases => Provider.of<CaseProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    CaseDetail? d;
    try {
      d = await _cases.loadDetail(widget.caseId);
    } catch (_) {
      d = null;
    }
    if (!mounted) return;
    setState(() {
      _detail = d;
      _loading = false;
    });
    for (final dec in d?.decisions ?? <Decision>[]) {
      final id = dec.signerId;
      if (id == null || _signers.containsKey(id)) continue;
      final name = await _cases.signerName(widget.caseId, id);
      if (name != null && mounted) setState(() => _signers[id] = name);
    }
  }

  Future<void> _open(String url, String name) async {
    final file = await _cases.download(url, name);
    if (!mounted) return;
    if (file == null ||
        (await OpenFilex.open(file.path)).type != ResultType.done) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("open_failed".i18n)));
    }
  }

  Future<void> _rectify() async {
    final detail = _detail;
    if (detail == null) return;
    final sent = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => _RectificationPage(detail: detail)));
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("rectification_sent".i18n)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      appBar: AppBar(title: Text("details".i18n)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? Center(
                  child:
                      TextButton(onPressed: _load, child: Text("retry".i18n)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: _content(context, d),
                  ),
                ),
    );
  }

  List<Widget> _content(BuildContext context, CaseDetail d) {
    final dateTime = DateFormat("yyyy. MMM d. HH:mm", "hu_HU");
    final date = DateFormat("yyyy. MMM d.", "hu_HU");
    final s = d.summary;
    return [
      _Card(children: [
        _Row("state".i18n, stateLabel(d.stateCode, s.stateName)),
        _Row("period".i18n, formatRange(s.start, s.end)),
        _Row("type".i18n, s.typeName),
        _Row("reason_title".i18n, s.reason),
        _Row("sent_at".i18n, s.sent == null ? "–" : dateTime.format(s.sent!)),
        _Row("handler".i18n, d.handlerName),
        _Row("student".i18n, d.studentName),
        _Row("edu_id".i18n, d.educationId),
      ]),
      if (d.needsRectification) ...[
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _rectify,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text("rectification".i18n),
        ),
      ],
      if (d.mandatoryDocs.isNotEmpty || d.otherDocs.isNotEmpty) ...[
        const SizedBox(height: 16),
        _Card(children: [
          for (final doc in d.mandatoryDocs)
            _DocTile(doc.name, Icons.assignment_rounded),
          for (final doc in d.otherDocs)
            _DocTile(doc.name, Icons.attach_file_rounded),
        ]),
      ],
      if (d.filedId != null) ...[
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _open(KretaAPI.printableCase(d.filedId!),
              "igazolas_${widget.caseId}.pdf"),
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: Text("printable".i18n),
        ),
      ],
      if (d.decisions.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text("decisions".i18n,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final dec in d.decisions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Card(children: [
              Text(dec.label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _Row("decision_date".i18n,
                  dec.date == null ? "–" : date.format(dec.date!)),
              if (dec.text != "–") Text(dec.text),
              if (dec.reason != "–") _Row("reason_title".i18n, dec.reason),
              if (dec.start != null)
                _Row("proven_absence".i18n, formatRange(dec.start, dec.end)),
              if (dec.signerId != null)
                _Row("signer".i18n, _signers[dec.signerId] ?? "…"),
              if (dec.filedId != null)
                TextButton.icon(
                  onPressed: () => _open(
                      KretaAPI.printableDecision(dec.filedId!),
                      "hatarozat_${dec.filedId}.pdf"),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text("printable".i18n),
                ),
            ]),
          ),
      ],
    ];
  }
}

class _RectificationPage extends StatefulWidget {
  const _RectificationPage({required this.detail});

  final CaseDetail detail;

  @override
  State<_RectificationPage> createState() => _RectificationPageState();
}

class _RectificationPageState extends State<_RectificationPage> {
  final _files = AttachmentController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _files.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _files.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("confirm_title".i18n),
        content: Text([
          "rectification_confirm".i18n,
          "",
          ..._files.uploaded.map((f) => "📎 ${f.name}"),
        ].join("\n")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("cancel".i18n)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("confirm_send".i18n)),
        ],
      ),
    );
    if (ok != true || !mounted) {
      if (mounted) setState(() => _sending = false);
      return;
    }
    final error = await Provider.of<CaseProvider>(context, listen: false)
        .submitRectification(widget.detail, _files.uploaded);
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
    final texts = widget.detail.decisions
        .where((d) => d.code?.startsWith("HIANYPOTLAS") ?? false)
        .map((d) => d.text)
        .where((t) => t != "–");
    return Scaffold(
      appBar: AppBar(title: Text("rectification_title".i18n)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        for (final t in texts)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(t, style: const TextStyle(fontSize: 16)),
          ),
        AttachmentSection(
          title: "attached_docs".i18n,
          controller: _files,
          enabled: !_sending,
        ),
        if (_files.hasFailed)
          Text("failed_hint".i18n,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed:
              canSubmitRectification(_files.uploaded, _files.uploading) &&
                      !_sending
                  ? _send
                  : null,
          icon: const Icon(Icons.send_rounded),
          label: Text("send".i18n),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
          ),
          Expanded(child: Text(value)),
        ]),
      );
}

class _DocTile extends StatelessWidget {
  const _DocTile(this.name, this.icon);

  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
        ]),
      );
}
