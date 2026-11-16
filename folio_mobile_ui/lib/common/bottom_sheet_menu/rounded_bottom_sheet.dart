import 'dart:ui' show ImageFilter;
import 'package:folio/theme/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:folio/theme/glass.dart';
import 'package:folio/helpers/hyper_os.dart';
import 'package:folio/theme/glass_settings.dart';

class RoundedBottomSheet extends StatelessWidget {
  const RoundedBottomSheet({
    super.key,
    this.child,
    this.borderRadius = 28.0,
    this.shrink = true,
    this.showHandle = true,
    this.backgroundColor,
    this.frostedSheets,
  });

  final Widget? child;
  final double borderRadius;
  final bool shrink;
  final bool showHandle;
  final Color? backgroundColor;

  /// Test hook; null = HyperOS decides.
  final bool? frostedSheets;

  @override
  Widget build(BuildContext context) {
    final content = _content(context);
    // Üveg: a see-through tinted panel with a lit rim, NOT live glass. A
    // live-glass sheet re-samples everything behind it every frame; at this
    // size that cost ~7 ms/frame on the Redmi and the 120 Hz open animation
    // stuttered (15.9 ms raster vs 8.3 ms budget, measured 2026-11-16; blur
    // and specular made no difference, the frosted "minimal" tier was worse
    // at 26.8 ms). iOS 26 does the same: a sheet turns opaque as it grows.
    // Refraction stays on the small controls (navbar, filters, switches).
    // A caller's own colour (a fully coloured sheet) still wins.
    if (backgroundColor == null && isGlassTheme(context)) {
      final theme = Theme.of(context);
      final dark = theme.brightness == Brightness.dark;
      final radius = BorderRadius.vertical(top: Radius.circular(borderRadius));
      // HyperOS: its own dialog/sheet material (miuix GlassMaterials
      // .dialogGlass: 60 dp blur + neutral grey), smooth at 120 Hz there.
      if (frostedSheets ?? HyperOS.isHyperOS) {
        return ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: dark ? const Color(0x9E1E1E20) : const Color(0xB8F5F5F5),
                border: Border.all(
                  width: 0.8,
                  color: Colors.white.withValues(alpha: dark ? 0.14 : 0.8),
                ),
              ),
              child: Theme(
                data: theme.copyWith(
                    colorScheme: _seeThrough(theme.colorScheme, dark)),
                child: content,
              ),
            ),
          ),
        );
      }
      return DecoratedBox(
        // the panel
        decoration: BoxDecoration(
          borderRadius: radius,
          color: theme.scaffoldBackgroundColor
              .withValues(alpha: tintaSheetPanelAlpha(dark)),
        ),
        child: DecoratedBox(
          // a soft wash of the theme colour from the top + the lit rim
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.secondary
                    .withValues(alpha: dark ? 0.10 : 0.06),
                theme.colorScheme.secondary.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.5],
            ),
            border: Border.all(
              width: 0.8,
              color: Colors.white.withValues(alpha: dark ? 0.14 : 0.8),
            ),
          ),
          child: Theme(
            // cards on the sheet stay see-through ("túl matt", 2026-11-16)
            data: theme.copyWith(
                colorScheme: _seeThrough(theme.colorScheme, dark)),
            child: content,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: content,
    );
  }

  /// The card colours, made translucent for the glass sheet.
  static ColorScheme _seeThrough(ColorScheme c, bool dark) {
    final a = tintaSheetCardAlpha(dark);
    Color t(Color x) => x.withValues(alpha: a);
    return c.copyWith(
      surface: t(c.surface),
      surfaceContainerLowest: t(c.surfaceContainerLowest),
      surfaceContainerLow: t(c.surfaceContainerLow),
      surfaceContainer: t(c.surfaceContainer),
      surfaceContainerHigh: t(c.surfaceContainerHigh),
      surfaceContainerHighest: t(c.surfaceContainerHighest),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      mainAxisSize: shrink ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (showHandle)
          Container(
            width: 42.0,
            height: 4.0,
            margin: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(45.0),
              color: AppColors.of(context).text.withValues(alpha: 0.10),
            ),
          ),
        if (child != null) child!,
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

Future<T?> showRoundedModalBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool rootNavigator = true,
  bool showHandle = true,
  Color? backgroundColor,
}) async {
  return await showModalBottomSheet<T>(
    useSafeArea: false,
    context: context,
    backgroundColor: const Color(0x00000000),
    elevation: 0,
    isDismissible: true,
    useRootNavigator: rootNavigator,
    isScrollControlled: true,
    builder: (context) => RoundedBottomSheet(
      backgroundColor: backgroundColor,
      showHandle: showHandle,
      child: child,
    ),
  );
}

PersistentBottomSheetController showRoundedBottomSheet(
  BuildContext context, {
  required Widget child,
}) {
  return showBottomSheet(
    context: context,
    backgroundColor: const Color(0x00000000),
    elevation: 12.0,
    builder: (context) => RoundedBottomSheet(child: child),
  );
}
