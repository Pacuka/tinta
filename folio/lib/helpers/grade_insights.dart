import 'package:flutter/material.dart';
import 'package:folio/helpers/average_helper.dart';
import 'package:folio_kreta_api/models/grade.dart';

/// "4,33" – Hungarian decimal comma; 0 (no grades) shows a dash.
String formatAverage(double v) =>
    v == 0 ? '–' : v.toStringAsFixed(2).replaceAll('.', ',');

/// Color for an average: blends the two neighbouring grade colors, so 4,50
/// sits between the 4 and the 5 color. [gradeColors] index 0..4 = grade 1..5.
Color averageColor(double avg, List<Color> gradeColors) {
  final v = avg.clamp(1.0, 5.0);
  final lo = v.floor();
  final frac = v - lo;
  if (frac == 0) return gradeColors[lo - 1];
  return Color.lerp(gradeColors[lo - 1], gradeColors[lo], frac)!;
}

/// Running average after each grade (oldest first), sampled down to
/// [maxPoints] (the last point is always the current average).
List<double> averageTrend(List<Grade> grades, {int maxPoints = 12}) {
  if (grades.length < 2) return [];
  final sorted = [...grades]..sort((a, b) => a.date.compareTo(b.date));
  final running = <double>[];
  for (var i = 1; i <= sorted.length; i++) {
    running.add(AverageHelper.averageEvals(sorted.sublist(0, i)));
  }
  if (running.length <= maxPoints) return running;
  final n = running.length;
  return List.generate(
      maxPoints, (i) => running[(i * (n - 1) / (maxPoints - 1)).round()]);
}
