import 'dart:io' show Platform;

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:folio/theme/glass.dart';
import 'package:folio/theme/glass_settings.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
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

    if (glass && Platform.isIOS) {
      // Üveg on iPhone: Apple's own tab bar (real Liquid Glass on iOS 26+,
      // the classic bar on older iOS).
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0.0),
          child: CNTabBar(
            items: [
              for (final i in items)
                CNTabBarItem(label: i.title, icon: CNSymbol(i.sfSymbol)),
            ],
            currentIndex: selectedIndex,
            onTap: onSelected,
            tint: colorScheme.secondary,
          ),
        ),
      );
    }

    if (glass) {
      // Üveg on Android: Liquid Glass tab bar (refraction, rim light, lens).
      return SafeArea(
        top: false,
        child: GlassTabBar.bottom(
          tabs: [
            for (final i in items)
              GlassTab(icon: i.icon, activeIcon: i.activeIcon, label: i.title),
          ],
          selectedIndex: selectedIndex,
          onTabSelected: onSelected,
          verticalPadding: 8,
          quality: tintaGlassQuality,
          settings: tintaBarSettings(dark),
          indicatorSettings: tintaIndicatorSettings(),
          indicatorColor: tintaIndicatorColor(dark),
          indicatorExpansion:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          selectedIconColor: tintaSelectedColor(colorScheme, dark),
          selectedLabelColor: tintaSelectedColor(colorScheme, dark),
          unselectedIconColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurface,
        ),
      );
    }

    return SafeArea(
      child: Padding(
        // iPhone: a SafeArea már kihagyja a rendszercsík helyét, a plusz
        // 10 pont miatt túl magasan lebegett a menü.
        padding: EdgeInsets.fromLTRB(
            20.0, 8.0, 20.0, Platform.isIOS ? 0.0 : 10.0),
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
