import 'package:flutter/material.dart';

class NavItem {
  final String title;
  final Widget icon;
  final Widget activeIcon;

  /// SF Symbol name for the native iPhone (Liquid Glass) tab bar.
  final String sfSymbol;

  const NavItem(
      {required this.title,
      required this.icon,
      required this.activeIcon,
      this.sfSymbol = 'circle'});
}

class NavbarItem extends StatelessWidget {
  const NavbarItem({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
    this.glass = false,
  });

  final NavItem item;
  final bool active;
  final void Function() onTap;

  /// Üveg theme: the active pill is a light "lens" instead of a solid chip.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.onSecondaryContainer;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // The pill holds icon and label and stays inside the 64 px bar with
      // the same margin all round, so it never pokes out of the capsule.
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: !active
                ? Colors.transparent
                : glass
                    ? colorScheme.secondary.withValues(alpha: 0.20)
                    : colorScheme.secondaryContainer,
            // Bar radius 36 minus the 5 px margin: the corners run parallel.
            borderRadius: BorderRadius.circular(31.0),
            border: Border.all(
              color: glass && active
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: active ? activeColor : inactiveColor,
                  size: 24.0,
                ),
                child: SizedBox(
                  height: 26.0,
                  child: Center(child: active ? item.activeIcon : item.icon),
                ),
              ),
              const SizedBox(height: 2.0),
              // A large system font would push the label out of the bar.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.1,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  // Start from the theme so the app font (Outfit) is kept.
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontSize: 11.0,
                    height: 1.2,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? activeColor : inactiveColor,
                  ),
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
