import 'dart:ui' show ImageFilter;
import 'package:folio/theme/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:folio/theme/glass.dart';
import 'package:folio/helpers/hyper_os.dart';
import 'package:folio_mobile_ui/common/glass_backdrop.dart';
import 'package:folio_mobile_ui/common/frozen_glass.dart';
import 'package:folio/theme/glass_settings.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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
    return TintaSheetSurface(
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      frostedSheets: frostedSheets,
      child: _content(context),
    );
  }

  /// The card colours, made translucent for the glass sheet.
  static ColorScheme seeThrough(ColorScheme c, bool dark) {
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

/// The surface every bottom sheet sits on.
///
/// * Üveg: live Liquid Glass (user, 2026-11-17: "minden menü legyen olyan",
///   half glass / half solid looked bad). Measured 15.9 ms/frame on the
///   Redmi at 120 Hz; accepted, the release notes say to use Üveg only if
///   the phone runs it smoothly.
/// * Üveg on HyperOS: the system's own frosted sheet material.
/// * Every other theme, or an explicit [backgroundColor]: the solid sheet.
class TintaSheetSurface extends StatelessWidget {
  const TintaSheetSurface({
    super.key,
    required this.child,
    this.borderRadius = 28.0,
    this.backgroundColor,
    this.frostedSheets,
  });

  final Widget child;
  final double borderRadius;
  final Color? backgroundColor;

  /// Test hook; null = HyperOS decides.
  final bool? frostedSheets;

  @override
  Widget build(BuildContext context) {
    // A sheet opened from an Üveg main page captures that page's Theme,
    // whose scaffold colour is transparent (so the backdrop shows). Inside
    // the sheet everything must see the real page colour again.
    final page = GlassPageBackground.maybeOf(context);
    if (page != null && Theme.of(context).scaffoldBackgroundColor != page) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(scaffoldBackgroundColor: page),
        child: Builder(builder: build),
      );
    }
    final radius = BorderRadius.vertical(top: Radius.circular(borderRadius));
    if (backgroundColor == null && isGlassTheme(context)) {
      final theme = Theme.of(context);
      final dark = theme.brightness == Brightness.dark;
      // cards on the sheet stay see-through ("túl matt", 2026-11-16)
      final inner = Theme(
        data: theme.copyWith(
            colorScheme:
                RoundedBottomSheet.seeThrough(theme.colorScheme, dark)),
        child: child,
      );
      final hyperOS = frostedSheets ?? HyperOS.isHyperOS;
      // A sheet in a popup route: frozen glass (photo of the page, blurred
      // once; smooth at 120 Hz). HyperOS: its own neutral grey material
      // (miuix GlassMaterials.dialogGlass).
      if (FrozenBackdrop.canFreeze(context)) {
        return FrozenGlass(
          borderRadius: radius,
          tint: hyperOS
              ? (dark ? const Color(0x9E1E1E20) : const Color(0xB8F5F5F5))
              : tintaFrozenTint(theme.scaffoldBackgroundColor, dark),
          blurSigma: hyperOS ? 30 : tintaFrozenBlur(dark),
          saturation: hyperOS ? 1.0 : 1.25,
          highlight: hyperOS ? 0.0 : (dark ? 0.08 : 0.25),
          rim: Colors.white.withValues(alpha: dark ? 0.14 : 0.8),
          child: inner,
        );
      }
      // A persistent sheet over a page that can still scroll: live glass.
      if (hyperOS) {
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
              child: inner,
            ),
          ),
        );
      }
      return AdaptiveGlass(
        shape: LiquidVerticalRoundedSuperellipse(
            topRadius: borderRadius, bottomRadius: 0),
        settings: tintaSheetSettings(dark),
        quality: tintaGlassQuality,
        child: inner,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: radius,
      ),
      child: child,
    );
  }
}

/// For a plain [showModalBottomSheet]: in Üveg the route paints nothing
/// (the [TintaSheetSurface] in [tintaSheetBody] does), otherwise the theme
/// default. Safe to call from callbacks.
Color? tintaSheetRouteColor(BuildContext context) =>
    isGlassThemeNow(context) ? Colors.transparent : null;

/// A plain sheet's body: on the glass surface in Üveg, unchanged otherwise.
/// [handle] adds the grab handle, for sheets whose route draws its own one
/// (`showDragHandle`) only outside Üveg.
Widget tintaSheetBody(BuildContext context,
        {double borderRadius = 28.0,
        bool handle = false,
        required Widget child}) =>
    isGlassTheme(context)
        ? TintaSheetSurface(
            borderRadius: borderRadius,
            child: handle
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 32.0,
                      height: 4.0,
                      margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.0),
                        color:
                            AppColors.of(context).text.withValues(alpha: 0.4),
                      ),
                    ),
                    child,
                  ])
                : child)
        : child;

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
