import 'package:flutter/material.dart';
import 'package:folio/models/release.dart';

const previewWarning =
    "Ezt a verziót még nem próbálták ki éles iskolai fiókkal, lehetnek benne hibák. "
    "Csak akkor telepítsd, ha szívesen segítesz tesztelni!";

/// A small, clearly-warning line for an untested pre-release (Settings only;
/// no popup, no badge).
class PreviewBanner extends StatelessWidget {
  const PreviewBanner(this.release, {super.key, required this.onTap});

  final Release release;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE08A00);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Material(
        color: orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Előzetes, nem tesztelt verzió: ${release.tag}",
                  style: const TextStyle(
                      color: orange,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: orange, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}
