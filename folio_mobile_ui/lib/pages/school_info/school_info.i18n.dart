import 'package:i18n_extension/i18n_extension.dart';

extension SchoolInfoLocalization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "questionnaires": "Teacher questionnaires",
          "window": "Open: %s – %s",
          "closed": "No questionnaire to fill in right now.",
          "deadline": "Deadline: %s",
          "send": "Send",
          "sending_note": "You can't change your answers after sending.",
          "confirm_send": "Send this questionnaire?",
          "sent": "Sent. Thank you!",
          "cancel": "Cancel",
          "leave": "Discard your answers?",
          "leave_yes": "Discard",
          "your_answer": "Your answer",
          "error": "Couldn't reach KRÉTA.",
          "retry": "Retry",
          "class_master": "Homeroom teacher",
          "write_email": "Write an email",
          "call": "Call",
          "no_contact": "KRÉTA has no contact for them.",
        },
        "hu-HU": {
          "questionnaires": "Tanári kérdőívek",
          "window": "Kitölthető: %s – %s",
          "closed": "Most nincs kitölthető kérdőív.",
          "deadline": "Határidő: %s",
          "send": "Beküldés",
          "sending_note": "Beküldés után a válaszaid már nem módosíthatók.",
          "confirm_send": "Beküldöd a kérdőívet?",
          "sent": "Beküldve. Köszönjük!",
          "cancel": "Mégse",
          "leave": "Elveted a válaszaidat?",
          "leave_yes": "Elvetem",
          "your_answer": "Válaszod",
          "error": "Nem értük el a KRÉTA-t.",
          "retry": "Újra",
          "class_master": "Osztályfőnök",
          "write_email": "E-mail írása",
          "call": "Hívás",
          "no_contact": "A KRÉTA-ban nincs elérhetősége.",
        },
        "de-DE": {
          "questionnaires": "Lehrerfragebögen",
          "window": "Offen: %s – %s",
          "closed": "Gerade kein Fragebogen offen.",
          "deadline": "Frist: %s",
          "send": "Senden",
          "sending_note": "Nach dem Senden kannst du nichts mehr ändern.",
          "confirm_send": "Fragebogen senden?",
          "sent": "Gesendet. Danke!",
          "cancel": "Abbrechen",
          "leave": "Antworten verwerfen?",
          "leave_yes": "Verwerfen",
          "your_answer": "Deine Antwort",
          "error": "KRÉTA ist nicht erreichbar.",
          "retry": "Erneut",
          "class_master": "Klassenlehrer:in",
          "write_email": "E-Mail schreiben",
          "call": "Anrufen",
          "no_contact": "In KRÉTA ist kein Kontakt hinterlegt.",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
}

String get questionnairesTitle => "questionnaires".i18n;
String get classMasterTitle => "class_master".i18n;
