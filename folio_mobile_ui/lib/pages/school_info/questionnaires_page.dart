import 'package:flutter/material.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/models/questionnaire.dart';
import 'package:folio_kreta_api/providers/questionnaire_provider.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/ink_stroke.dart';
import 'package:i18n_extension/i18n_extension.dart' show I18n;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'school_info.i18n.dart';

/// Header shared by the two questionnaire screens.
Widget _header(BuildContext context, String title) {
  final scheme = Theme.of(context).colorScheme;
  return SafeArea(
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
          child: Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontSize: 26.0,
                  fontWeight: FontWeight.w800)),
        ),
      ]),
    ),
  );
}

String _date(BuildContext context, DateTime d) =>
    DateFormat("MMM d.", I18n.of(context).locale.toString()).format(d);

/// PedTér questionnaires: one card per teacher.
class QuestionnairesPage extends StatefulWidget {
  const QuestionnairesPage({super.key});

  @override
  State<QuestionnairesPage> createState() => _QuestionnairesPageState();
}

class _QuestionnairesPageState extends State<QuestionnairesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Provider.of<SchoolInfoProvider>(context, listen: false).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchoolInfoProvider>(context);
    final scheme = Theme.of(context).colorScheme;
    final text = AppColors.of(context).text;
    final now = DateTime.now();
    final open = provider.open(now);
    final round = provider.round;

    Widget body;
    if (provider.loading && round == null) {
      body = ListView(children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ]);
    } else if (provider.error != null && round == null) {
      body = ListView(padding: const EdgeInsets.all(24.0), children: [
        const SizedBox(height: 60),
        Text("error".i18n, textAlign: TextAlign.center),
        Center(
            child: TextButton(
                onPressed: provider.fetch, child: Text("retry".i18n))),
      ]);
    } else if (open.isEmpty) {
      body = ListView(children: [Empty(subtitle: "closed".i18n)]);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
        children: [
          if (round?.start != null && round?.end != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 8.0),
              child: Text(
                  "window".i18n.fill([
                    _date(context, round!.start!),
                    _date(context, round.end!)
                  ]),
                  style: TextStyle(color: text.withValues(alpha: 0.6))),
            ),
          for (final q in open)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Material(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16.0),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  title: Text(q.teacherName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([
                    if (q.subjects.isNotEmpty) q.subjects,
                    if (q.deadline != null)
                      "deadline".i18n.fill([_date(context, q.deadline!)]),
                  ].join(" · ")),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => QuestionnaireFillPage(q))),
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, "questionnaires".i18n),
          const InkStroke(style: InkStyle.drop),
          Expanded(
            child: RefreshIndicator(
                color: scheme.secondary, onRefresh: provider.fetch, child: body),
          ),
        ],
      ),
    );
  }
}

/// Filling in one teacher's questionnaire.
class QuestionnaireFillPage extends StatefulWidget {
  const QuestionnaireFillPage(this.questionnaire, {super.key});

  final TeacherQuestionnaire questionnaire;

  @override
  State<QuestionnaireFillPage> createState() => _QuestionnaireFillPageState();
}

class _QuestionnaireFillPageState extends State<QuestionnaireFillPage> {
  final Map<int, String> _answers = {};
  bool _sending = false;

  Future<bool> _confirm(String title, String yes) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: title == "confirm_send".i18n
              ? Text("sending_note".i18n)
              : null,
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text("cancel".i18n)),
            FilledButton(
                onPressed: () => Navigator.pop(c, true), child: Text(yes)),
          ],
        ),
      ) ??
      false;

  Future<void> _send() async {
    if (!await _confirm("confirm_send".i18n, "send".i18n)) return;
    if (!mounted) return;
    setState(() => _sending = true);
    final provider = Provider.of<SchoolInfoProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.submit(widget.questionnaire, _answers);
    if (!mounted) return;
    setState(() => _sending = false);
    messenger.showSnackBar(SnackBar(content: Text(error ?? "sent".i18n)));
    if (error == null) {
      _answers.clear();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questionnaire;
    final scheme = Theme.of(context).colorScheme;
    final complete = q.isComplete(_answers);

    return PopScope(
      canPop: _answers.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirm("leave".i18n, "leave_yes".i18n)) {
          _answers.clear();
          nav.pop();
        }
      },
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, q.teacherName),
            if (q.subjects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(70.0, 2.0, 20.0, 0.0),
                child: Text(q.subjects,
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.6))),
              ),
            const InkStroke(style: InkStyle.drop),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 24.0),
                children: [
                  for (final (i, question) in q.questions.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${i + 1}. ${question.text}",
                              style: const TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10.0),
                          if (question.type == QuestionType.grade)
                            Row(
                              children: [
                                for (var n = 1; n <= 5; n++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3.0),
                                      child: ChoiceChip(
                                        showCheckmark: false,
                                        label: SizedBox(
                                            width: double.infinity,
                                            child: Text("$n",
                                                textAlign: TextAlign.center)),
                                        selected: _answers[question.id] == "$n",
                                        onSelected: (_) => setState(
                                            () => _answers[question.id] = "$n"),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          else
                            TextField(
                              maxLength: questionnaireTextLimit,
                              minLines: 2,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: "your_answer".i18n,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (v) => setState(() {
                                if (v.isEmpty) {
                                  _answers.remove(question.id);
                                } else {
                                  _answers[question.id] = v;
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: scheme.secondary,
                        foregroundColor: scheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14.0)),
                    onPressed: complete && !_sending ? _send : null,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text("send".i18n),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
