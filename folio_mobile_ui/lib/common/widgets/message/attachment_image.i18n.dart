import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "download_failed": "Couldn't download it. Tap to try again.",
        },
        "hu-HU": {
          "download_failed": "Nem sikerült letölteni. Koppints az újrapróbáláshoz.",
        },
        "de-DE": {
          "download_failed": "Download fehlgeschlagen. Tippe, um es erneut zu versuchen.",
        },
      };

  String get i18n => localize(this, _t);
}
