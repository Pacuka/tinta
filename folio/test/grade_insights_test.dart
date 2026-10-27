import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/helpers/grade_insights.dart';
import 'package:folio_kreta_api/models/grade.dart';

Grade _grade(int value, DateTime date) => Grade.fromJson({
      "Uid": "$value-${date.toIso8601String()}",
      "KeszitesDatuma": date.toIso8601String(),
      "SzamErtek": value,
      "SulySzazalekErteke": 100,
    });

const _colors = [
  Color(0xFFFF0000),
  Color(0xFFFF8800),
  Color(0xFFFFFF00),
  Color(0xFF88FF00),
  Color(0xFF00FF00),
];

void main() {
  group('formatAverage', () {
    test('two decimals with comma', () {
      expect(formatAverage(4.333), '4,33');
      expect(formatAverage(5), '5,00');
    });
    test('zero shows dash', () => expect(formatAverage(0), '–'));
  });

  group('averageColor', () {
    test('integer average equals that grade color', () {
      expect(averageColor(5.0, _colors), _colors[4]);
      expect(averageColor(3.0, _colors), _colors[2]);
    });
    test('half way lerps between neighbours', () {
      expect(averageColor(4.5, _colors), Color.lerp(_colors[3], _colors[4], .5));
    });
    test('clamps out of range', () {
      expect(averageColor(0.2, _colors), _colors[0]);
      expect(averageColor(7, _colors), _colors[4]);
    });
  });

  group('averageTrend', () {
    test('fewer than 2 grades gives no points', () {
      expect(averageTrend([_grade(5, DateTime(2026, 9, 1))]), isEmpty);
    });
    test('running average in date order', () {
      final g = [_grade(1, DateTime(2026, 9, 2)), _grade(5, DateTime(2026, 9, 1))];
      expect(averageTrend(g), [5.0, 3.0]);
    });
    test('sampled to maxPoints, last is overall average', () {
      final g = List.generate(
          30, (i) => _grade(i.isEven ? 5 : 2, DateTime(2026, 9, 1 + i)));
      final t = averageTrend(g);
      expect(t.length, 12);
      expect(t.last, closeTo(3.5, 1e-9));
    });
  });
}
