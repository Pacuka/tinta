import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Hungarian main name days, bundled offline (name -> ["MM-DD"], non-leap).
/// Sources: sbolch/name-days (MIT) for main days, names missing there from
/// hu.wikipedia.org "Magyar névnapok listája betűrendben" (CC BY-SA 4.0).
class NameDay {
  static Map<String, List<String>>? _days;

  static Future<void> load() async {
    if (_days != null) return;
    final raw = await rootBundle.loadString('assets/data/namedays.json');
    _days = (jsonDecode(raw) as Map<String, dynamic>)
        .map((name, days) => MapEntry(name, List<String>.from(days)));
  }

  /// True if any of [names] has a name day on [date]. False until [load] ran.
  static bool isNameDay(Iterable<String> names, DateTime date) {
    final days = _days;
    if (days == null) return false;
    final key = _calendarKey(date);
    if (key == null) return false;
    return names.any((n) => days[n]?.contains(key) ?? false);
  }

  // In leap years Feb 24 is the leap day (no name days) and the
  // Feb 24-28 name days move one day later.
  static String? _calendarKey(DateTime date) {
    int day = date.day;
    final leap = date.year % 4 == 0 &&
        (date.year % 100 != 0 || date.year % 400 == 0);
    if (leap && date.month == 2) {
      if (day == 24) return null;
      if (day > 24) day -= 1;
    }
    return "${date.month.toString().padLeft(2, '0')}-"
        "${day.toString().padLeft(2, '0')}";
  }
}

/// Confetti only on the first app start of the day, not on every restart.
Future<bool> confettiAllowedToday() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/confetti_day');
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";
    if (await file.exists() && await file.readAsString() == today) {
      return false;
    }
    await file.writeAsString(today);
    return true;
  } catch (_) {
    return false;
  }
}
