import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "recipients": "Recipients",
          "send_message": "Send Message",
          "send": "Send",
          "sent": "Message sent successfully.",
          "message_subject": "Subject...",
          "message_text": "Message text...",
          "select_recipient": "Add Recipient",
          "cant_send": "You can't send a message to one of the recipients!",
          "attachments": "Attachments",
          "attach_failed": "An attachment failed to upload. Retry or remove it.",
          "send_failed": "Couldn't send the message. Check your connection and try again.",
        },
        "hu-HU": {
          "recipients": "Címzettek",
          "send_message": "Üzenetküldés",
          "send": "Küldés",
          "sent": "Sikeres üzenetküldés.",
          "message_subject": "Tárgy...",
          "message_text": "Üzenet szövege...",
          "select_recipient": "Címzett hozzáadása",
          "cant_send": "Az egyik címzettnek nem küldhetsz üzenetet!",
          "attachments": "Csatolmányok",
          "attach_failed": "Egy csatolmányt nem sikerült feltölteni. Próbáld újra, vagy töröld.",
          "send_failed": "Nem sikerült elküldeni az üzenetet. Ellenőrizd a netet, és próbáld újra.",
        },
        "de-DE": {
          "recipients": "Empfänger",
          "send_message": "Nachricht senden",
          "send": "Versenden",
          "sent": "Nachricht erfolgreich gesendet.",
          "message_subject": "Betreff...",
          "message_text": "Nachrichtentext...",
          "select_recipient": "Empfänger hinzufügen",
          "cant_send": "Einem der Empfänger kannst du keine Nachricht senden!",
          "attachments": "Anhänge",
          "attach_failed": "Ein Anhang konnte nicht hochgeladen werden. Versuche es erneut oder entferne ihn.",
          "send_failed": "Die Nachricht konnte nicht gesendet werden. Prüfe deine Verbindung und versuche es erneut.",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

