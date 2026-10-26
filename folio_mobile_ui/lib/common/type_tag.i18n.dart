import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "exam_tag": "Test",
          "oral_tag": "Oral",
          "practical_tag": "Practical",
          "homework_tag": "Homework",
        },
        "hu-HU": {
          "exam_tag": "Dolgozat",
          "oral_tag": "Felelés",
          "practical_tag": "Gyakorlat",
          "homework_tag": "Házi",
        },
        "de-DE": {
          "exam_tag": "Test",
          "oral_tag": "Mündlich",
          "practical_tag": "Praxis",
          "homework_tag": "Hausaufgabe",
        }
      };

  String get i18n => localize(this, _t);
}
