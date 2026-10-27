import 'package:i18n_extension/i18n_extension.dart';

extension JustificationLocalization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "justify": "Justify",
          "justifications": "Justifications",
          "new_justification": "New justification",
          "no_justifications": "You haven't sent a justification yet.",
          "retry": "Retry",
          "sent_ok": "Justification sent.",
          "from": "First day",
          "to": "Last day",
          "type": "Type of justification",
          "reason": "Reason (optional)",
          "send": "Send",
          "cancel": "Cancel",
          "confirm_title": "Send to the school?",
          "confirm_body": "This goes to the school as a real request:",
          "confirm_send": "Send it",
          "pick_date": "Pick a date",
          "bad_range": "The first day can't be after the last day.",
        },
        "hu-HU": {
          "justify": "Igazolás",
          "justifications": "Igazolások",
          "new_justification": "Új igazolás",
          "no_justifications": "Még nem küldtél be igazolást.",
          "retry": "Újra",
          "sent_ok": "Igazolás beküldve.",
          "from": "Első nap",
          "to": "Utolsó nap",
          "type": "Igazolás típusa",
          "reason": "Indoklás (nem kötelező)",
          "send": "Küldés",
          "cancel": "Mégse",
          "confirm_title": "Beküldöd az iskolának?",
          "confirm_body": "Ez valódi kérelemként megy az iskolához:",
          "confirm_send": "Beküldöm",
          "pick_date": "Válassz napot",
          "bad_range": "Az első nap nem lehet később, mint az utolsó.",
        },
      };

  String get i18n => localize(this, _t);
}
