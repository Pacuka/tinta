import 'package:folio/theme/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:folio/theme/glass.dart';
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
  });

  final Widget? child;
  final double borderRadius;
  final bool shrink;
  final bool showHandle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final content = _content(context);
    // Üveg: frosted glass, flat bottom edge. A caller's own colour (a fully
    // coloured sheet) still wins.
    if (backgroundColor == null && isGlassTheme(context)) {
      return AdaptiveGlass(
        shape: LiquidVerticalRoundedSuperellipse(
            topRadius: borderRadius, bottomRadius: 0),
        settings:
            tintaBarSettings(Theme.of(context).brightness == Brightness.dark),
        quality: tintaGlassQuality,
        child: content,
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
