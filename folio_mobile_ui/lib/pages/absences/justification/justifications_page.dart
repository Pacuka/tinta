import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:folio_kreta_api/models/justification.dart';
import 'package:folio_kreta_api/providers/case_provider.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/ink_stroke.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'justification.i18n.dart';
import 'justification_form.dart';

/// Parent accounts: earlier absence justifications + "new" button.
class JustificationsPage extends StatefulWidget {
  const JustificationsPage({super.key});

  @override
  State<JustificationsPage> createState() => _JustificationsPageState();
}

class _JustificationsPageState extends State<JustificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Provider.of<CaseProvider>(context, listen: false).load());
  }

  Future<void> _openForm() async {
    final sent = await Navigator.of(context).push<bool>(
        CupertinoPageRoute(builder: (_) => const JustificationForm()));
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("sent_ok".i18n)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cases = Provider.of<CaseProvider>(context);
    final scheme = Theme.of(context).colorScheme;
    final canCreate = cases.error == null && !cases.loading;

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
                    "justifications".i18n,
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
          const InkStroke(style: InkStyle.pen),
          Expanded(
            child: RefreshIndicator(
              color: scheme.secondary,
              onRefresh: cases.load,
              child: _body(context, cases),
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add_rounded),
              label: Text("new_justification".i18n),
            )
          : null,
    );
  }

  Widget _body(BuildContext context, CaseProvider cases) {
    if (cases.loading && cases.cases.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ]);
    }
    if (cases.error != null) {
      return ListView(padding: const EdgeInsets.all(24.0), children: [
        const SizedBox(height: 60),
        Text(cases.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16.0)),
        const SizedBox(height: 16),
        Center(
          child: TextButton(onPressed: cases.load, child: Text("retry".i18n)),
        ),
      ]);
    }
    if (cases.cases.isEmpty) {
      return ListView(children: [Empty(subtitle: "no_justifications".i18n)]);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
      itemCount: cases.cases.length,
      itemBuilder: (context, i) => _CaseTile(cases.cases[i]),
    );
  }
}

String formatRange(DateTime? start, DateTime? end) {
  final f = DateFormat("MMM d.", "hu_HU");
  if (start == null) return "–";
  if (end == null || DateUtils.isSameDay(start, end)) return f.format(start);
  return "${f.format(start)} – ${f.format(end)}";
}

class _CaseTile extends StatelessWidget {
  const _CaseTile(this.item);

  final JustificationCase item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(formatRange(item.start, item.end),
                style: const TextStyle(
                    fontSize: 16.0, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(item.typeName,
                style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.7))),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(item.stateName,
              style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: scheme.secondary)),
        ),
      ]),
    );
  }
}
