import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:folio/theme/glass.dart';
import 'package:folio_mobile_ui/screens/navigation/navbar_item.dart';

class Navbar extends StatelessWidget {
  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final void Function(int index) onSelected;
  final List<NavItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final glass = isGlassTheme(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final row = Row(
      children: List.generate(
        items.length,
        (index) => Expanded(
          child: NavbarItem(
            item: items[index],
            active: index == selectedIndex,
            onTap: () => onSelected(index),
            glass: glass,
          ),
        ),
      ),
    );

    if (glass) {
      // Üveg: floating frosted capsule with a rim of light on top.
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 10.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.45 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 64.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36.0),
                    border: Border.all(
                        color: Colors.white
                            .withValues(alpha: dark ? 0.16 : 0.7)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.06, 1.0],
                      colors: [
                        Colors.white.withValues(alpha: dark ? 0.22 : 0.85),
                        colorScheme.surfaceContainerHigh
                            .withValues(alpha: dark ? 0.42 : 0.55),
                        colorScheme.surfaceContainerHigh
                            .withValues(alpha: dark ? 0.42 : 0.55),
                      ],
                    ),
                  ),
                  child: row,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 10.0),
        child: Container(
          height: 64.0,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(36.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: row,
        ),
      ),
    );
  }
}
