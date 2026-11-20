import 'package:flutter/material.dart';
import 'package:folio/theme/glass.dart';
import 'package:folio/theme/glass_settings.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/frozen_glass.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// The corner radius of a dialog [shape], or [fallback].
double _radiusOf(ShapeBorder? shape, double fallback) {
  if (shape is RoundedRectangleBorder) {
    final r = shape.borderRadius;
    if (r is BorderRadius) return r.topLeft.x;
  }
  return fallback;
}

/// The glass a dialog sits on in Üveg (same material as the sheets, so
/// every menu and window looks the same: user, 2026-11-17).
class TintaDialogGlass extends StatelessWidget {
  const TintaDialogGlass(
      {super.key, required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final inner = Theme(
      data: theme.copyWith(
          colorScheme: RoundedBottomSheet.seeThrough(theme.colorScheme, dark)),
      child: child,
    );
    // in a dialog route: the same frozen glass as the sheets
    if (FrozenBackdrop.canFreeze(context)) {
      return FrozenGlass(
        borderRadius: BorderRadius.circular(radius),
        tint: tintaFrozenTint(theme.scaffoldBackgroundColor, dark),
        blurSigma: tintaFrozenBlur(dark),
        highlight: dark ? 0.08 : 0.25,
        rim: Colors.white.withValues(alpha: dark ? 0.14 : 0.8),
        child: inner,
      );
    }
    return AdaptiveGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      settings: tintaSheetSettings(dark),
      quality: tintaGlassQuality,
      child: inner,
    );
  }
}

/// [Dialog] that turns into glass in Üveg; unchanged in every other theme.
class TintaDialog extends StatelessWidget {
  const TintaDialog({
    super.key,
    required this.child,
    this.shape,
    this.insetPadding,
  });

  final Widget child;
  final ShapeBorder? shape;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    if (!isGlassTheme(context)) {
      return Dialog(shape: shape, insetPadding: insetPadding, child: child);
    }
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: shape,
      insetPadding: insetPadding,
      child: TintaDialogGlass(radius: _radiusOf(shape, 28.0), child: child),
    );
  }
}

/// [AlertDialog] that turns into glass in Üveg; every other theme gets the
/// plain [AlertDialog] with the same arguments.
///
/// In Üveg the alert's own layout (icon, title, content, actions) is
/// rebuilt on the glass: a nested [AlertDialog] would stretch to the whole
/// screen inside the outer dialog.
class TintaAlertDialog extends StatelessWidget {
  const TintaAlertDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    this.shape,
    this.insetPadding,
  });

  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final ShapeBorder? shape;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    if (!isGlassTheme(context)) {
      return AlertDialog(
        icon: icon,
        title: title,
        content: content,
        actions: actions,
        titlePadding: titlePadding,
        contentPadding: contentPadding,
        actionsPadding: actionsPadding,
        shape: shape,
        insetPadding: insetPadding,
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasActions = actions != null && actions!.isNotEmpty;
    // Same defaults as Material 3's AlertDialog.
    final children = <Widget>[
      if (icon != null)
        Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, title == null ? 16 : 0),
          child: IconTheme.merge(
            data: IconThemeData(color: cs.secondary),
            child: Center(child: icon!),
          ),
        ),
      if (title != null)
        Padding(
          padding: titlePadding ??
              EdgeInsets.fromLTRB(
                  24, icon == null ? 24 : 16, 24, content == null ? 20 : 16),
          child: DefaultTextStyle(
            style: theme.textTheme.headlineSmall!.copyWith(color: cs.onSurface),
            textAlign: icon == null ? TextAlign.start : TextAlign.center,
            child: Semantics(container: true, child: title!),
          ),
        ),
      if (content != null)
        Flexible(
          child: Padding(
            padding: contentPadding ??
                EdgeInsets.fromLTRB(24, title == null ? 24 : 0, 24, 24),
            child: DefaultTextStyle(
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: cs.onSurfaceVariant),
              child: content!,
            ),
          ),
        ),
      if (hasActions)
        Padding(
          padding: actionsPadding ?? const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            overflowAlignment: OverflowBarAlignment.end,
            children: actions!,
          ),
        ),
    ];

    return TintaDialog(
      shape: shape,
      insetPadding: insetPadding,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
