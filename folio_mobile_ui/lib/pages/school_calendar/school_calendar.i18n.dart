import 'package:i18n_extension/i18n_extension.dart';

extension SchoolCalendarLocalization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          "school_calendar": "School year",
          "now_free": "Now",
          "next_free": "Next day off",
          "days_left": "%s more days",
          "last_day": "Last day",
          "in_days": "in %s days",
          "tomorrow": "tomorrow",
          "days": "%s days",
          "no_school": "No school",
          "show_past": "Show earlier days",
          "hide_past": "Hide earlier days",
          "empty": "KRÉTA hasn't sent the school year calendar.",
          "error": "Couldn't reach KRÉTA.",
          "retry": "Retry",
          "nothing_left": "No more days off this school year.",
        },
        "hu-HU": {
          "school_calendar": "Tanév rendje",
          "now_free": "Most",
          "next_free": "Következő szabadnap",
          "days_left": "még %s nap",
          "last_day": "utolsó nap",
          "in_days": "%s nap múlva",
          "tomorrow": "holnap",
          "days": "%s nap",
          "no_school": "Nincs tanítás",
          "show_past": "Korábbiak mutatása",
          "hide_past": "Korábbiak elrejtése",
          "empty": "A KRÉTA nem küldte el a tanév rendjét.",
          "error": "Nem értük el a KRÉTA-t.",
          "retry": "Újra",
          "nothing_left": "Ebben a tanévben nincs több szünnap.",
        },
        "de-DE": {
          "school_calendar": "Schuljahr",
          "now_free": "Jetzt",
          "next_free": "Nächster freier Tag",
          "days_left": "noch %s Tage",
          "last_day": "letzter Tag",
          "in_days": "in %s Tagen",
          "tomorrow": "morgen",
          "days": "%s Tage",
          "no_school": "Kein Unterricht",
          "show_past": "Frühere anzeigen",
          "hide_past": "Frühere ausblenden",
          "empty": "KRÉTA hat den Schuljahreskalender nicht gesendet.",
          "error": "KRÉTA ist nicht erreichbar.",
          "retry": "Erneut",
          "nothing_left": "Keine freien Tage mehr in diesem Schuljahr.",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
}

String get schoolCalendarTitle => "school_calendar".i18n;
