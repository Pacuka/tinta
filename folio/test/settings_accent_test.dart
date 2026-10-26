import 'package:flutter_test/flutter_test.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';

void main() {
  test('fresh install defaults to kobalt', () {
    expect(SettingsProvider.defaultSettings().accentColor, AccentColor.kobalt);
  });

  test('fromMap keeps the saved accent color', () {
    final map = SettingsProvider.defaultSettings().toMap();
    map['accent_color'] = AccentColor.petrol.index;
    expect(SettingsProvider.fromMap(map, database: DatabaseProvider()).accentColor, AccentColor.petrol);
  });

  test('fromMap falls back to kobalt on out-of-range index', () {
    final map = SettingsProvider.defaultSettings().toMap();
    map['accent_color'] = 999;
    expect(SettingsProvider.fromMap(map, database: DatabaseProvider()).accentColor, AccentColor.kobalt);
  });
}
