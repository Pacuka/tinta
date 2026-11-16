import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart' show showCupertinoDialog;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:folio/theme/glass_settings.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

/// Called from callbacks, so no listening; a tree without settings (some
/// widget tests) counts as "not glass".
bool _glass(BuildContext context) {
  try {
    return Provider.of<SettingsProvider>(context, listen: false).accentColor ==
        AccentColor.uveg;
  } on ProviderNotFoundException {
    return false;
  }
}

/// A short yes/no (or single "OK") question.
///
/// * Üveg + iPhone: Apple's own alert ([CNAlert]).
/// * Üveg + Android: the package's glass dialog.
/// * Every other theme: [fallback], the call site's original dialog, shown
///   with [showDialog] exactly as before. It must pop `true` for the
///   confirming button and `false` (or nothing) otherwise.
///
/// [cancelLabel] null = one button only (an info / "I understand" alert).
/// Resolves to true only when the confirming button was pressed.
Future<bool> showTintaConfirm(
  BuildContext context, {
  String? title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  bool barrierDismissible = true,
  required WidgetBuilder fallback,
}) async {
  if (!_glass(context)) {
    final r = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: fallback,
    );
    return r == true;
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final r = await CNAlert.show<bool>(
      context: context,
      title: title,
      message: message,
      actions: [
        if (cancelLabel != null)
          CNAlertAction<bool>(label: cancelLabel, value: false, isCancel: true),
        CNAlertAction<bool>(
          label: confirmLabel,
          value: true,
          isDestructive: destructive,
          isDefault: !destructive,
        ),
      ],
    );
    return r?.value == true;
  }

  final dark = Theme.of(context).brightness == Brightness.dark;
  final nav = Navigator.of(context, rootNavigator: true);
  // GlassDialog.show puts the dialog in a route with no Material above it,
  // so text fell back to the debug style (yellow underline, monospace) on the
  // Redmi. Same route type and barrier as the package, plus a transparent
  // Material for the app's text style.
  final r = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    // = the package's iOS 27 alert barrier (src/, not exported).
    barrierColor: dark ? const Color(0x77000000) : const Color(0x35000000),
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: _dialog(context, title, message, confirmLabel, cancelLabel,
          destructive, dark, nav),
    ),
  );
  return r == true;
}

Widget _dialog(
  BuildContext context,
  String? title,
  String? message,
  String confirmLabel,
  String? cancelLabel,
  bool destructive,
  bool dark,
  NavigatorState nav,
) =>
    GlassDialog(
      title: title,
      message: message,
      settings: tintaSheetSettings(dark),
      quality: tintaGlassQuality,
      actions: [
        if (cancelLabel != null)
          GlassDialogAction(
            label: cancelLabel,
            onPressed: () => nav.pop(false),
          ),
        GlassDialogAction(
          label: confirmLabel,
          isDestructive: destructive,
          isPrimary: !destructive,
          onPressed: () => nav.pop(true),
        ),
      ],
    );
