import 'package:flutter/material.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:i18n_extension/i18n_extension.dart' show I18n;
import 'package:intl/intl.dart';
import 'homework_view.i18n.dart';

/// Earlier texts of a homework the teacher changed, newest first.
class HomeworkHistory extends StatefulWidget {
  const HomeworkHistory(this.homework, {super.key});

  final Homework homework;

  @override
  State<HomeworkHistory> createState() => _HomeworkHistoryState();
}

class _HomeworkHistoryState extends State<HomeworkHistory> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final versions = widget.homework.previous.reversed.toList();
    final text = AppColors.of(context).text;
    final code = I18n.locale.countryCode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key("homework-history"),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(children: [
                Icon(Icons.history_rounded, size: 18.0, color: text),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    "previous_versions".i18n.fill([versions.length]),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(_open
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded),
              ]),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14.0, 0, 14.0, 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "history_note".i18n,
                    style: TextStyle(
                        fontSize: 12.0, color: text.withValues(alpha: 0.65)),
                  ),
                  for (final v in versions) ...[
                    const SizedBox(height: 12.0),
                    Text(
                      "version_before".i18n.fill([
                        DateFormat('MMM d. HH:mm', code).format(v.replacedAt)
                      ]),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    SelectableText(
                      v.content,
                      style: TextStyle(
                        color: text.withValues(alpha: 0.9),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (v.deadline != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "${"deadline".i18n}: ${DateFormat('MMM d.', code).format(v.deadline!)}",
                          style: TextStyle(
                              fontSize: 12.0,
                              color: text.withValues(alpha: 0.65)),
                        ),
                      ),
                    if (v.attachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "${"attachments".i18n}: ${v.attachments.join(", ")}",
                          style: TextStyle(
                              fontSize: 12.0,
                              color: text.withValues(alpha: 0.65)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
