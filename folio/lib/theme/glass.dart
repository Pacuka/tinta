import 'package:flutter/widgets.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:provider/provider.dart';

/// True while the "Üveg" (Liquid Glass-like) theme is selected. Everything
/// glassy is gated by this, so other themes stay untouched.
bool isGlassTheme(BuildContext context) =>
    Provider.of<SettingsProvider>(context).accentColor == AccentColor.uveg;
