import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wear_data_provider.dart';

class PairingScreen extends StatelessWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<WearDataProvider>(
      builder: (context, data, _) {
        final code = data.pairingCode;
        final connColor = data.connected
            ? const Color(0xFF69F0AE)
            : const Color(0xFFFF5252);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Watch icon
                  Container(
                    width: 46.0,
                    height: 46.0,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child:
                        Icon(Icons.watch_rounded, size: 24.0, color: cs.primary),
                  ),
                  const SizedBox(height: 12.0),

                  const Text(
                    'Párosítás',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Add meg ezt a kódot\na Tinta appban:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14.0),

                  // Code badge — HyperOS card style
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 11.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      code.isEmpty ? '--- ---' : _fmt(code),
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: 6.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14.0),

                  // Connection indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                            color: connColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        data.connected
                            ? 'Telefon megtalálva'
                            : 'Nincs telefon kapcsolat',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: connColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _fmt(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}
