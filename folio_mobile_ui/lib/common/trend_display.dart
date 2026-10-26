import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';

class TrendDisplay<T extends num> extends StatelessWidget {
  const TrendDisplay(
      {super.key, required this.current, required this.previous, this.padding});

  final T current;
  final T previous;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    const upIcon = "▲";
    const downIcon = "▼";
    final upColor = Colors.lightGreenAccent.shade700;
    const downColor = Colors.redAccent;

    Color color;
    String icon;

    double percentage;

    // Change in average grade points (was shown as a bogus "%": diff*100).
    if (previous > 0) {
      percentage = (current - previous).toDouble();
    } else {
      percentage = 0.0;
    }

    final String percentageText = percentage
        .abs()
        .toStringAsFixed(2)
        .replaceAll(
            '.', I18n.of(context).locale.languageCode != 'en' ? ',' : '.');

    if (!percentage.isNegative) {
      color = upColor;
      icon = upIcon;
    } else {
      color = downColor;
      icon = downIcon;
    }

    if (percentage.abs() < 0.005) {
      return const SizedBox();
    }

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 2.0),
            child: Text(
              icon,
              style: TextStyle(fontSize: 18.0, color: color),
            ),
          ),
          Text(percentageText, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
