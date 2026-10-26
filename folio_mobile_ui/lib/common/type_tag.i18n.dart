import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "exam_tag": "Test",
          "homework_tag": "Homework",
        },
        "hu-HU": {
          "exam_tag": "Dolgozat",
          "homework_tag": "Házi",
        },
        "de-DE": {
          "exam_tag": "Test",
          "homework_tag": "Hausaufgabe",
        }
      };

  String get i18n => localize(this, _t);
}
