// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_navigation_screen.dart';
import 'services/saved_hand_storage_service.dart';
import 'services/saved_hand_manager_service.dart';
import 'services/session_note_service.dart';
import 'services/session_pin_service.dart';
import 'services/training_pack_storage_service.dart';
import 'services/daily_hand_service.dart';
import 'services/spot_of_the_day_service.dart';
import 'services/action_sync_service.dart';
import 'services/folded_players_service.dart';
import 'services/all_in_players_service.dart';
import 'services/user_preferences_service.dart';
import 'services/tag_service.dart';
import 'services/ignored_mistake_service.dart';
import 'services/goals_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/cloud_training_history_service.dart';
import 'services/training_spot_storage_service.dart';
import 'services/evaluation_executor_service.dart';
import "services/training_stats_service.dart";
import "services/achievement_engine.dart";
import 'services/goal_engine.dart';
import 'services/streak_service.dart';
import 'services/reminder_service.dart';
import 'services/next_step_engine.dart';
import 'user_preferences.dart';
import 'services/user_action_logger.dart';
import 'services/leaderboard_service.dart';
import 'services/cloud_backup_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CloudSyncService()),
        Provider(create: (_) => CloudTrainingHistoryService()),
        ChangeNotifierProvider(create: (_) => TrainingStatsService()..load()),
        ChangeNotifierProvider(create: (_) => SavedHandStorageService()..load()),
        ChangeNotifierProvider(
          create: (context) => SavedHandManagerService(
            storage: context.read<SavedHandStorageService>(),
            cloud: context.read<CloudSyncService>(),
            stats: context.read<TrainingStatsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionNoteService()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionPinService()..load(),
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
        ChangeNotifierProvider(
          create: (_) => IgnoredMistakeService()..load(),
        ),
        ChangeNotifierProvider(create: (_) => GoalsService()..load()),
        ChangeNotifierProvider(create: (_) => StreakService()..load()),
        ChangeNotifierProvider(
          create: (context) =>
              AchievementEngine(stats: context.read<TrainingStatsService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => GoalEngine(stats: context.read<TrainingStatsService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ReminderService(
            spotService: context.read<SpotOfTheDayService>(),
            goalEngine: context.read<GoalEngine>(),
            streakService: context.read<StreakService>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => NextStepEngine(
            hands: context.read<SavedHandManagerService>(),
            goals: context.read<GoalEngine>(),
            streak: context.read<StreakService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              LeaderboardService(stats: context.read<TrainingStatsService>())
                ..load(),
        ),
        Provider(create: (_) => EvaluationExecutorService()),
        Provider(create: (_) => CloudSyncService()),
        ChangeNotifierProvider(create: (_) => UserActionLogger()..load()),
        ChangeNotifierProvider(
          create: (context) => CloudBackupService(
            stats: context.read<TrainingStatsService>(),
            streak: context.read<StreakService>(),
            goals: context.read<GoalsService>(),
            log: context.read<UserActionLogger>(),
          )..load(),
        ),
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
    context.read<UserActionLogger>().log('opened_app');
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
      navigatorKey: navigatorKey,
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
