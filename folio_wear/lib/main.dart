import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:wear/wear.dart';
import 'providers/wear_data_provider.dart';
import 'screens/connecting_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/wear_shell.dart';
import 'theme/wear_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('hu', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => WearDataProvider(),
      child: const FolioWearApp(),
    ),
  );
}

class FolioWearApp extends StatelessWidget {
  const FolioWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: WearColors.cobalt,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const WatchShape(builder: _buildForShape),
    );
  }
}

Widget _buildForShape(BuildContext context, WearShape shape, Widget? child) =>
    const _WearRoot();

// ─────────────────────────────────────────────────────────────────────────────

class _WearRoot extends StatelessWidget {
  const _WearRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<WearDataProvider>(builder: (context, data, _) {
      final hasData =
          data.lessons.isNotEmpty || data.notifications.isNotEmpty;
      if (!data.loaded) return const ConnectingScreen();
      if (!data.isPaired) return const PairingScreen();
      if (!hasData && data.lastSync == null) return const ConnectingScreen();
      return const WearShell();
    });
  }
}
