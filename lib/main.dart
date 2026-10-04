import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme.dart';
import 'ui/screens/main_menu_screen.dart';

void main() {
  runApp(const ProviderScope(child: SpaceTradersApp()));
}

class SpaceTradersApp extends StatelessWidget {
  const SpaceTradersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Traders',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainMenuScreen(),
    );
  }
}
