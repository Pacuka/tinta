import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "exam_tag": "Test",
          "oral_tag": "Oral",
          "practical_tag": "Practical",
          "homework_tag": "Homework",
          "homework_modified_tag": "Modified",
        },
        "hu-HU": {
          "exam_tag": "Dolgozat",
          "oral_tag": "Felelés",
          "practical_tag": "Gyakorlat",
          "homework_tag": "Házi",
          "homework_modified_tag": "Módosítva",
        },
        "de-DE": {
          "exam_tag": "Test",
          "oral_tag": "Mündlich",
          "practical_tag": "Praxis",
          "homework_tag": "Hausaufgabe",
          "homework_modified_tag": "Geändert",
        }
      };

  String get i18n => localize(this, _t);
}
