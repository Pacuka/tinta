import 'dart:math';

import 'package:folio/theme/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:folio/theme/glass.dart';
import 'package:folio/theme/glass_settings.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class FilterBar extends StatefulWidget implements PreferredSizeWidget {
  const FilterBar({
    super.key,
    required this.items,
    required this.controller,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0),
    this.disableFading = false,
    this.scrollable = true,
    this.censored = false,
    this.tabAlignment = TabAlignment.start,
    this.pillStyle = false,
  }) : assert(items.length == controller.length);

  final List<Widget> items;
  final TabController controller;
  final EdgeInsetsGeometry padding;
  final Function(int)? onTap;
  final bool disableFading;
  final bool scrollable;
  final bool censored;
  final TabAlignment tabAlignment;
  final bool pillStyle;

  @override
  Size get preferredSize => Size.fromHeight(pillStyle ? 48.0 : 42.0);

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  List<double> censoredItemsWidth = [];
  @override
  void initState() {
    super.initState();

    censoredItemsWidth = List.generate(
            widget.items.length, (index) => 25 + Random().nextDouble() * 50)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.pillStyle && !widget.censored && isGlassTheme(context)) {
      final segments = widget.items.map(_glassSegment).toList();
      if (!segments.contains(null)) {
        return _glassBar(context, segments.cast<GlassSegment>());
      }
    }
    final tabbar = TabBar(
      controller: widget.controller,
      isScrollable: widget.scrollable,
      physics: const BouncingScrollPhysics(),
      // label
      labelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15.0,
          ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      labelColor:
          widget.pillStyle ? colorScheme.secondary : colorScheme.primary,
      unselectedLabelColor: AppColors.of(context).text.withValues(alpha: 0.55),
      // indicator
      indicatorColor: colorScheme.primary,
      indicatorSize: widget.pillStyle
          ? TabBarIndicatorSize.tab
          : TabBarIndicatorSize.label,
      indicator: widget.pillStyle
          ? (isGlassTheme(context)
              ? BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12)),
                )
              : BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.0),
                ))
          : null,
      indicatorPadding: widget.pillStyle
          ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0)
          : EdgeInsets.zero,
      // underline (bottom border)
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(const Color(0x00000000)),
      // tabs
      padding: EdgeInsets.zero,
      tabs: widget.censored
          ? censoredItemsWidth
              .map(
                (e) => Tab(
                  child: Container(
                    width: e,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).text.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              )
              .toList()
          : widget.items,
      onTap: widget.onTap,
      tabAlignment: widget.tabAlignment,
    );

    return Container(
      width: MediaQuery.of(context).size.width,
      height: widget.pillStyle ? 48.0 : 48.0,
      padding: widget.padding,
      child: widget.disableFading
          ? tabbar
          : AnimatedBuilder(
              animation: widget.controller.animation!,
              builder: (ctx, child) {
                // avoid fading over selected tab
                return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      final Color bg =
                          Theme.of(context).scaffoldBackgroundColor;
                      final double index = widget.controller.animation!.value;
                      return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            index < 0.2 ? Colors.transparent : bg,
                            Colors.transparent,
                            Colors.transparent,
                            index > widget.controller.length - 1.2
                                ? Colors.transparent
                                : bg
                          ],
                          stops: const [
                            0,
                            0.1,
                            0.9,
                            1
                          ]).createShader(bounds);
                    },
                    blendMode: BlendMode.dstOut,
                    child: child);
              },
              child: tabbar,
            ),
    );
  }

  /// Üveg: the filter pills as a Liquid Glass segmented control, driven by
  /// the same [TabController] as the pages below it.
  Widget _glassBar(BuildContext context, List<GlassSegment> segments) {
    final colorScheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final controller = widget.controller;
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 48.0,
      padding: widget.padding,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: controller.animation!,
        builder: (context, _) => GlassSegmentedControl.scrollable(
          segments: segments,
          selectedIndex: controller.animation!.value.round(),
          onSegmentSelected: (i) {
            controller.animateTo(i);
            widget.onTap?.call(i);
          },
          height: 40.0,
          quality: tintaGlassQuality,
          settings: tintaBarSettings(dark),
          indicatorSettings: tintaIndicatorSettings(),
          indicatorColor: tintaIndicatorColor(dark),
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          selectedTextStyle: TextStyle(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
              fontSize: 15.0),
          unselectedTextStyle: TextStyle(
              color: AppColors.of(context).text.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 15.0),
        ),
      ),
    );
  }

  /// A plain `Tab(text:)`, or a tab whose child holds a label and a count
  /// (the home page's unread badges). Anything else keeps the old TabBar.
  GlassSegment? _glassSegment(Widget item) {
    if (item is! Tab) return null;
    if (item.text != null) return GlassSegment(label: item.text);
    final texts = <String>[];
    void collect(Widget? w) {
      if (w is Text && w.data != null) {
        texts.add(w.data!);
      } else if (w is Flex) {
        w.children.forEach(collect);
      } else if (w is Container) {
        collect(w.child);
      } else if (w is Padding) {
        collect(w.child);
      }
    }

    collect(item.child);
    if (texts.isEmpty || texts.length > 2) return null;
    if (texts.length == 1) return GlassSegment(label: texts.first);
    final colorScheme = Theme.of(context).colorScheme;
    return GlassSegment(
      label: texts.first,
      icon: Container(
        constraints: const BoxConstraints(minWidth: 18.0),
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
        decoration: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(9.0),
        ),
        child: Text(
          texts[1],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSecondary,
          ),
        ),
      ),
    );
  }
}
