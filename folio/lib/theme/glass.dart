import 'package:flutter/material.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:provider/provider.dart';

/// True while the "Üveg" (Liquid Glass-like) theme is selected. Everything
/// glassy is gated by this, so other themes stay untouched.
bool isGlassTheme(BuildContext context) =>
    Provider.of<SettingsProvider>(context).accentColor == AccentColor.uveg;

/// Üveg theme: the hairline of light around cards; [BorderSide.none] for
/// every other theme.
BorderSide glassHairline(BuildContext context) => isGlassTheme(context)
    ? BorderSide(
        width: 0.8,
        color: Colors.white.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.07 : 0.8))
    : BorderSide.none;

/// Card corner radius: a little rounder in the Üveg theme.
double glassRadius(BuildContext context, double normal) =>
    isGlassTheme(context) ? 18.0 : normal;

/// Whether the theme takes its colours from the phone (wallpaper / system
/// theme, e.g. HyperOS or Material You). Üveg does when the phone offers
/// them; otherwise (iPhone, older Android) it keeps its own blue palette.
bool followsSystemColors(AccentColor c, {required bool hasSystemPalette}) =>
    c == AccentColor.adaptive ||
    (c == AccentColor.uveg && hasSystemPalette);
