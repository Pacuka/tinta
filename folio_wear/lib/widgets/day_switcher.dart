import 'package:flutter/material.dart';
import '../theme/wear_theme.dart';
import 'edge_fade.dart';

/// Today or the next school day, nothing further: the phone is for the rest.
class DaySwitcher extends StatelessWidget {
  final String nextLabel;
  final bool showNext;
  final ValueChanged<bool> onChanged;

  const DaySwitcher({
    super.key,
    required this.nextLabel,
    required this.showNext,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => EdgeFade(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Chip(
                label: 'Ma',
                selected: !showNext,
                onTap: () => onChanged(false)),
            const SizedBox(width: 6.0),
            _Chip(
                label: nextLabel,
                selected: showNext,
                onTap: () => onChanged(true)),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: selected ? WearColors.cobalt : WearColors.surface,
            borderRadius: BorderRadius.circular(99.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : WearColors.muted,
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
