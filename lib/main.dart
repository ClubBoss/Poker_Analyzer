// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/saved_hand_storage_service.dart';
import 'services/saved_hand_manager_service.dart';
import 'services/training_pack_storage_service.dart';
import 'services/daily_hand_service.dart';
import 'services/spot_of_the_day_service.dart';
import 'services/action_sync_service.dart';
import 'services/folded_players_service.dart';
import 'services/all_in_players_service.dart';
import 'services/user_preferences_service.dart';
import 'services/tag_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/training_spot_storage_service.dart';
import 'user_preferences.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CloudSyncService()),
        ChangeNotifierProvider(create: (_) => SavedHandStorageService()..load()),
        ChangeNotifierProvider(
          create: (context) => SavedHandManagerService(
            storage: context.read<SavedHandStorageService>(),
            cloud: context.read<CloudSyncService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => TrainingPackStorageService()..load()),
        ChangeNotifierProvider(create: (_) => DailyHandService()..load()),
        ChangeNotifierProvider(create: (_) => SpotOfTheDayService()..load()),
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
        Provider(create: (_) => CloudSyncService()),
      ],
      child: const PokerAIAnalyzerApp(),
    ),
  );
}

class PokerAIAnalyzerApp extends StatefulWidget {
  const PokerAIAnalyzerApp({super.key});

  @override
  State<PokerAIAnalyzerApp> createState() => _PokerAIAnalyzerAppState();
}

class _PokerAIAnalyzerAppState extends State<PokerAIAnalyzerApp> {
  late final TrainingSpotStorageService _spotStorage;

  @override
  void initState() {
    super.initState();
    _spotStorage = TrainingSpotStorageService(
      cloud: context.read<CloudSyncService>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialSync());
  }

  Future<void> _initialSync() async {
    final cloud = context.read<CloudSyncService>();
    final handManager = context.read<SavedHandManagerService>();
    final spots = await _spotStorage.load();
    for (final spot in spots) {
      await cloud.uploadSpot(spot);
    }
    for (final hand in handManager.hands) {
      await cloud.uploadHand(hand);
    }
  }

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
      home: const MainNavigationScreen(),
    );
  }
}
