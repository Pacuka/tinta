import 'package:flutter/material.dart';
import 'package:folio/theme/colors/accent.dart';

/// A Tinta beépített témáinak színei (spec: 2026-10-25-tinta-1.0-design.md).
class TintaPalette {
  const TintaPalette({
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.highlight,
    Color? examMark,
    this.container,
  }) : examMark = examMark ?? accent;

  final Color accent;
  final Color onAccent;
  final Color background;
  final Color highlight;
  final Color examMark;

  /// Kiemelő konténerszín (chipek, menü-jelölő). Null = az accent halvány változata.
  final Color? container;
}

const _amber = Color(0xFFE0A526);

const Map<AccentColor, TintaPalette> _light = {
  AccentColor.kobalt: TintaPalette(
    accent: Color(0xFF2440C8),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFF6F7F9),
    highlight: Color(0xFFFFFFFF),
    container: Color(0xFFDCE2FF),
  ),
  AccentColor.feketeSarga: TintaPalette(
    accent: Color(0xFF121212),
    onAccent: Color(0xFFF2F2EE),
    background: Color(0xFFFAFAF8),
    highlight: Color(0xFFFFFFFF),
    container: Color(0xFFFFE14D),
  ),
  AccentColor.petrol: TintaPalette(
    accent: Color(0xFF0F5C66),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFF4F7F7),
    highlight: Color(0xFFFFFFFF),
    examMark: _amber,
    container: Color(0xFFC9E9EC),
  ),
  AccentColor.uveg: TintaPalette(
    accent: Color(0xFF2440C8),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFEEF1F8),
    highlight: Color(0xFFFFFFFF),
    container: Color(0xFFDCE2FF),
  ),
};

const Map<AccentColor, TintaPalette> _dark = {
  AccentColor.kobalt: TintaPalette(
    accent: Color(0xFF9DB0FF),
    onAccent: Color(0xFF0D1A66),
    background: Color(0xFF101218),
    highlight: Color(0xFF1B1E27),
    container: Color(0xFF25306A),
  ),
  AccentColor.feketeSarga: TintaPalette(
    accent: Color(0xFFFFE14D),
    onAccent: Color(0xFF121212),
    background: Color(0xFF0F0F0F),
    highlight: Color(0xFF1C1C1B),
    container: Color(0xFF3A3412),
  ),
  AccentColor.petrol: TintaPalette(
    accent: Color(0xFF5FC9D4),
    onAccent: Color(0xFF032C31),
    background: Color(0xFF0C1416),
    highlight: Color(0xFF152124),
    examMark: _amber,
    container: Color(0xFF163E43),
  ),
  AccentColor.uveg: TintaPalette(
    accent: Color(0xFF9DB0FF),
    onAccent: Color(0xFF0D1A66),
    background: Color(0xFF0D0F15),
    highlight: Color(0xFF1A1D26),
    container: Color(0xFF25306A),
  ),
};

/// A Tinta-téma színei, vagy null, ha [c] nem Tinta-téma.
TintaPalette? tintaPalette(AccentColor c, Brightness b) =>
    (b == Brightness.light ? _light : _dark)[c];
