import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "deadline": "Deadline",
          "entered": "Entered",
          "modified": "Modified",
          "previous_versions": "Earlier versions (%s)",
          "version_before": "Before %s",
          "history_note": "KRÉTA doesn't say when the homework was changed. The time shows when Tinta noticed it.",
          "attachments": "Attachments",
        },
        "hu-HU": {
          "deadline": "Határidő",
          "entered": "Beírva",
          "modified": "Módosítva",
          "previous_versions": "Korábbi verziók (%s)",
          "version_before": "Így szólt %s előtt",
          "history_note": "A KRÉTA nem mondja meg, mikor írták át a házit. Az időpont azt mutatja, mikor vette észre a Tinta.",
          "attachments": "Csatolmányok",
        },
        "de-DE": {
          "deadline": "Termin",
          "entered": "Eingetragen",
          "modified": "Geändert",
          "previous_versions": "Frühere Versionen (%s)",
          "version_before": "Vor %s",
          "history_note": "KRÉTA gibt nicht an, wann die Hausaufgabe geändert wurde. Die Zeit zeigt, wann Tinta es bemerkt hat.",
          "attachments": "Anhänge",
        }
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}
