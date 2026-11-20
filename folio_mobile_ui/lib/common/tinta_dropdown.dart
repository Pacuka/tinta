import 'package:flutter/material.dart';
import 'package:folio/theme/glass.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';

/// The settings dropdown. Every theme but Üveg gets the plain
/// [DropdownButton]; in Üveg the choices open on a glass bottom sheet with
/// a tick, because the Material dropdown menu can't be made glass and a
/// solid menu among the glass ones looked out of place (user, 2026-11-20).
///
/// Every item's child must be a [Text] (its text is the sheet row's label).
class TintaDropdown<T> extends StatelessWidget {
  const TintaDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.style,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (!isGlassTheme(context)) {
      return DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(12.0),
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: style,
          items: items,
          onChanged: onChanged,
        ),
      );
    }

    final selected = items.where((i) => i.value == value).firstOrNull;
    return InkWell(
      borderRadius: BorderRadius.circular(12.0),
      onTap: () => _pick(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultTextStyle.merge(
              style: style,
              child: selected?.child ?? const SizedBox(),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                color: style?.color ?? Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  static String _label(Widget w) => w is Text ? (w.data ?? '') : '';

  Future<void> _pick(BuildContext context) async {
    final picked = await showRoundedModalBottomSheet<_Picked<T>>(
      context,
      child: Builder(builder: (sheet) {
        final accent = Theme.of(sheet).colorScheme.secondary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                ListTile(
                  title: Text(
                    _label(item.child),
                    style: TextStyle(
                      fontWeight: item.value == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: item.value == value
                      ? Icon(Icons.check_rounded, color: accent)
                      : null,
                  onTap: () => Navigator.of(sheet).pop(_Picked(item.value)),
                ),
            ],
          ),
        );
      }),
    );
    if (picked != null && picked.value != value) onChanged(picked.value);
  }
}

/// Wraps the choice so a dismissed sheet (null) differs from a null value.
class _Picked<T> {
  const _Picked(this.value);
  final T? value;
}
