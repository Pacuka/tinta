import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/home_widget_helper.dart';

void main() {
  test('widget colours follow the theme and are opaque', () {
    final light = HomeWidgetHelper.widgetColors(ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    ));
    final dark = HomeWidgetHelper.widgetColors(ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, brightness: Brightness.dark),
    ));
    expect(light.keys,
        containsAll(['bg', 'card', 'text', 'dim', 'accent', 'container']));
    for (final v in [...light.values, ...dark.values]) {
      expect(v >> 24, 0xFF); // RemoteViews draws no half-transparent text
    }
    expect(light['text'], isNot(dark['text']));
  });
}
