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
  // Üveg: tells the edge fade whether more filters hide off-screen.
  final ScrollController _glassScroll = ScrollController();

  @override
  void initState() {
    super.initState();

    censoredItemsWidth = List.generate(
            widget.items.length, (index) => 25 + Random().nextDouble() * 50)
        .toList();
  }

  @override
  void dispose() {
    _glassScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.pillStyle &&
        !widget.censored &&
        isGlassTheme(context) &&
        widget.items.every((item) => _glassParts(item) != null)) {
      return _glassBar(context);
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
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
  Widget _glassBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final controller = widget.controller;
    final selectedStyle = TextStyle(
        color: tintaSelectedColor(colorScheme, dark),
        fontWeight: FontWeight.w600,
        fontSize: 15.0);
    final unselectedStyle = TextStyle(
        color: AppColors.of(context).text.withValues(alpha: 0.7),
        fontWeight: FontWeight.w600,
        fontSize: 15.0);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 48.0,
      padding: widget.padding,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: Listenable.merge([controller.animation!, _glassScroll]),
        builder: (context, _) {
          final selected = controller.animation!.value.round();
          final bar = GlassSegmentedControl.scrollable(
            segments: [
              for (final (i, item) in widget.items.indexed)
                _glassSegment(
                    item, i == selected ? selectedStyle : unselectedStyle),
            ],
            selectedIndex: selected,
            onSegmentSelected: (i) {
              controller.animateTo(i);
              widget.onTap?.call(i);
            },
            scrollController: _glassScroll,
            height: 40.0,
            quality: tintaGlassQuality,
            settings: tintaBarSettings(dark),
            indicatorSettings: tintaIndicatorSettings(),
            indicatorColor: tintaIndicatorColor(dark),
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            selectedTextStyle: selectedStyle,
            unselectedTextStyle: unselectedStyle,
          );
          return _edgeFade(bar);
        },
      ),
    );
  }

  /// Fades the side where more filters are hidden, so a cut-off label
  /// ("Üzenete") reads as "scroll for more" instead of a glitch.
  Widget _edgeFade(Widget child) {
    final pos = _glassScroll.hasClients && _glassScroll.positions.length == 1
        ? _glassScroll.position
        : null;
    if (pos == null || !pos.hasContentDimensions) return child;
    final fadeLeft = pos.pixels > pos.minScrollExtent + 1;
    final fadeRight = pos.pixels < pos.maxScrollExtent - 1;
    if (!fadeLeft && !fadeRight) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          fadeLeft ? Colors.transparent : Colors.black,
          Colors.black,
          Colors.black,
          fadeRight ? Colors.transparent : Colors.black,
        ],
        stops: const [0, 0.08, 0.92, 1],
      ).createShader(bounds),
      child: child,
    );
  }

  /// The label and optional count of a filter: a plain `Tab(text:)`, or a
  /// tab whose child holds a label and a count (the home page's unread
  /// badges). Null for anything else, which keeps the old TabBar.
  (String, String?)? _glassParts(Widget item) {
    if (item is! Tab) return null;
    if (item.text != null) return (item.text!, null);
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
    return (texts.first, texts.length == 2 ? texts[1] : null);
  }

  /// The package stacks an icon above its label, so a counted filter is
  /// built as one "icon" row (label + badge) to keep the badge beside it.
  GlassSegment _glassSegment(Widget item, TextStyle style) {
    final (label, count) = _glassParts(item)!;
    if (count == null) return GlassSegment(label: label);
    final colorScheme = Theme.of(context).colorScheme;
    return GlassSegment(
      id: label,
      semanticLabel: "$label, $count",
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, maxLines: 1, style: style),
          const SizedBox(width: 6.0),
          Container(
            constraints: const BoxConstraints(minWidth: 18.0),
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(9.0),
            ),
            child: Text(
              count,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
