import 'package:flutter/material.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio/theme/glass_settings.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

/// Rebuilds on theme change; a tree without settings (some widget tests)
/// counts as "not glass".
bool _glass(BuildContext context) {
  try {
    return Provider.of<SettingsProvider>(context).accentColor ==
        AccentColor.uveg;
  } on ProviderNotFoundException {
    return false;
  }
}

/// On/off switch: the package's glass switch in Üveg, Flutter's [Switch]
/// with the same parameters everywhere else. [onChanged] null = disabled.
class TintaSwitch extends StatelessWidget {
  const TintaSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.materialTapTargetSize,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final MaterialTapTargetSize? materialTapTargetSize;

  @override
  Widget build(BuildContext context) {
    if (!_glass(context)) {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        materialTapTargetSize: materialTapTargetSize,
      );
    }
    final enabled = onChanged != null;
    // GlassSwitch has no disabled state: block taps and dim it like
    // Material does.
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: GlassSwitch(
          value: value,
          onChanged: onChanged ?? (_) {},
          activeColor: activeColor,
          quality: tintaGlassQuality,
        ),
      ),
    );
  }
}

/// Slider: the package's glass slider in Üveg, Flutter's [Slider] with the
/// same parameters everywhere else. [onChanged] null = disabled.
class TintaSlider extends StatelessWidget {
  const TintaSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.onChangeEnd,
    this.activeColor,
    this.thumbColor,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double>? onChangeEnd;
  final Color? activeColor;
  final Color? thumbColor;

  @override
  Widget build(BuildContext context) {
    if (!_glass(context)) {
      return Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChangeEnd: onChangeEnd,
        activeColor: activeColor,
        thumbColor: thumbColor,
      );
    }
    // The glass thumb stays white like on iOS; the track takes the accent.
    return GlassSlider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChangeEnd: onChangeEnd,
      activeColor: activeColor,
      quality: tintaGlassQuality,
    );
  }
}
