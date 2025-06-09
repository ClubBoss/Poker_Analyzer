// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';

void main() {
  runApp(const PokerAIAnalyzerApp());
}

class PokerAIAnalyzerApp extends StatelessWidget {
  const PokerAIAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker AI Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        scaffoldBackgroundColor: Colors.black,
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Roboto',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
