import 'package:flutter/material.dart';

/// Kis szöveges címke a lista elemek jobb oldalán (pl. „Házi”, „Dolgozat”).
class TypeTag extends StatelessWidget {
  const TypeTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
