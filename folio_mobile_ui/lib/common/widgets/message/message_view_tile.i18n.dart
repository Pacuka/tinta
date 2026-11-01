import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "me": "me",
          "to": "to",
          "to_trash": "Move to trash",
          "trashed": "Moved to trash.",
          "restore": "Restore",
          "restored": "Message restored.",
          "delete_forever": "Delete permanently",
          "delete_forever_q": "Delete permanently?",
          "delete_forever_body": "The message will be deleted from KRÉTA too. This can't be undone.",
          "deleted": "Message deleted.",
          "cancel": "Cancel",
          "undo": "Undo",
          "action_failed": "Didn't work. Check your connection and try again.",
        },
        "hu-HU": {
          "me": "én",
          "to": "Címzett:",
          "to_trash": "Kukába",
          "trashed": "Kukába került.",
          "restore": "Visszaállítás",
          "restored": "Üzenet visszaállítva.",
          "delete_forever": "Végleges törlés",
          "delete_forever_q": "Végleg törlöd?",
          "delete_forever_body": "Az üzenet a KRÉTÁ-ból is törlődik. Ezt nem lehet visszavonni.",
          "deleted": "Üzenet törölve.",
          "cancel": "Mégse",
          "undo": "Visszavonás",
          "action_failed": "Nem sikerült. Ellenőrizd a netet, és próbáld újra.",
        },
        "de-DE": {
          "me": "mich",
          "to": "zu",
          "to_trash": "In den Papierkorb",
          "trashed": "In den Papierkorb verschoben.",
          "restore": "Wiederherstellen",
          "restored": "Nachricht wiederhergestellt.",
          "delete_forever": "Endgültig löschen",
          "delete_forever_q": "Endgültig löschen?",
          "delete_forever_body": "Die Nachricht wird auch in KRÉTA gelöscht. Das kann nicht rückgängig gemacht werden.",
          "deleted": "Nachricht gelöscht.",
          "cancel": "Abbrechen",
          "undo": "Rückgängig",
          "action_failed": "Hat nicht geklappt. Prüfe die Verbindung und versuche es erneut.",
        }
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}

