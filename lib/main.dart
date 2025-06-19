// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_menu_screen.dart';
import 'services/saved_hand_storage_service.dart';
import 'services/saved_hand_manager_service.dart';
import 'services/training_pack_storage_service.dart';
import 'services/daily_hand_service.dart';
import 'services/action_sync_service.dart';
import 'services/folded_players_service.dart';
import 'services/all_in_players_service.dart';
import 'services/user_preferences_service.dart';
import 'services/tag_service.dart';
import 'user_preferences.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SavedHandStorageService()..load()),
        ChangeNotifierProvider(
          create: (context) =>
              SavedHandManagerService(storage: context.read<SavedHandStorageService>()),
        ),
        ChangeNotifierProvider(create: (_) => TrainingPackStorageService()..load()),
        ChangeNotifierProvider(create: (_) => DailyHandService()..load()),
        ChangeNotifierProvider(create: (_) => AllInPlayersService()),
        ChangeNotifierProvider(create: (_) => FoldedPlayersService()),
        ChangeNotifierProvider(
          create: (context) => ActionSyncService(
              foldedPlayers: context.read<FoldedPlayersService>(),
              allInPlayers: context.read<AllInPlayersService>()),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final service = UserPreferencesService();
            UserPreferences.init(service);
            service.load();
            return service;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => TagService()..load(),
        ),
      ],
      child: const PokerAIAnalyzerApp(),
    ),
  );
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
