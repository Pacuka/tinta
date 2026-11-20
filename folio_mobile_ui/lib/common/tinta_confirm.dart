import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/accent.dart';
import 'package:provider/provider.dart';
import 'package:folio_mobile_ui/common/tinta_dialog.dart';

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
/// * Üveg + Android: [TintaAlertDialog] on frozen glass.
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

  // Android: the app's own glass alert, on the same frozen glass as every
  // other sheet and dialog (2026-11-20).
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => TintaAlertDialog(
      title: title == null ? null : Text(title),
      content: message == null ? null : Text(message),
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error)
              : null,
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return r == true;
}
