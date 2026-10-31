import 'package:flutter/cupertino.dart';
import 'package:folio/helpers/update_notifier.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_mobile_ui/common/widgets/absence/absence_view.dart';
import 'package:folio_mobile_ui/common/widgets/exam/exam_view.dart';
import 'package:folio_mobile_ui/common/widgets/grade/grade_view.dart';
import 'package:folio_mobile_ui/common/widgets/homework/homework_view.dart';
import 'package:folio_mobile_ui/common/widgets/message/message_viewable.dart';
import 'package:folio_mobile_ui/pages/absences/absences_page.dart';
import 'package:folio_mobile_ui/pages/consulting/consulting_page.dart';
import 'package:folio_mobile_ui/pages/messages/messages_page.dart';
import 'package:provider/provider.dart';

/// Opens what a tapped notification is about (see [notificationPayload]).
///
/// The background check may have seen the item before the app did, so when
/// it is missing the matching provider is refreshed once. If it still can't
/// be found, the page it belongs to is opened instead.
Future<void> openFromNotification(
  BuildContext context,
  String payload, {
  required void Function(String page) setPage,
}) async {
  final (type, id) = parseNotificationPayload(payload);

  void push(Widget page) => Navigator.of(context, rootNavigator: true)
      .push(CupertinoPageRoute(builder: (_) => page));

  // Finds the item, refreshing its provider once when it isn't there yet.
  Future<T?> find<T>(
      List<T> Function() items, bool Function(T) match, Future<void> Function() fetch) async {
    for (final t in items()) {
      if (match(t)) return t;
    }
    try {
      await fetch();
    } catch (_) {}
    for (final t in items()) {
      if (match(t)) return t;
    }
    return null;
  }

  switch (type) {
    case "grade":
      setPage("grades");
      final p = Provider.of<GradeProvider>(context, listen: false);
      final grade = await find(() => p.grades, (g) => g.id == id, p.fetch);
      if (grade != null && context.mounted) {
        GradeView.show(grade, context: context);
      }
    case "exam":
      final p = Provider.of<ExamProvider>(context, listen: false);
      final exam = await find(() => p.exams, (e) => e.id == id, p.fetch);
      if (exam != null && context.mounted) ExamView.show(exam, context: context);
    case "homework":
      final p = Provider.of<HomeworkProvider>(context, listen: false);
      final hw = await find(() => p.homework, (h) => h.id == id, p.fetch);
      if (hw != null && context.mounted) HomeworkView.show(hw, context: context);
    case "absence":
      final p = Provider.of<AbsenceProvider>(context, listen: false);
      final absence = await find(() => p.absences, (a) => a.id == id, p.fetch);
      if (!context.mounted) return;
      absence != null
          ? AbsenceView.show(absence, context: context)
          : push(const AbsencesPage());
    case "message":
      final p = Provider.of<MessageProvider>(context, listen: false);
      final message =
          await find(() => p.messages, (m) => "${m.id}" == id, p.fetch);
      if (!context.mounted) return;
      if (message != null) {
        p.markSeen(message);
        MessagePopup.show(context: context, message: message);
      } else {
        push(const MessagesPage());
      }
    case "timetable":
      setPage("timetable");
    case "consulting":
      push(const ConsultingPage());
  }
}
