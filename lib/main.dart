// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/saved_hand_storage_service.dart';
import 'services/saved_hand_manager_service.dart';
import 'services/session_note_service.dart';
import 'services/session_pin_service.dart';
import 'services/training_pack_storage_service.dart';
import 'services/template_storage_service.dart';
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
import 'services/daily_reminder_service.dart';
import 'services/next_step_engine.dart';
import 'services/drill_suggestion_engine.dart';
import 'services/daily_target_service.dart';
import 'services/daily_tip_service.dart';
import 'services/xp_tracker_service.dart';
import 'services/weekly_challenge_service.dart';
import 'services/category_usage_service.dart';
import 'user_preferences.dart';
import 'services/user_action_logger.dart';
import 'services/mistake_review_pack_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
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
          create: (context) => MistakeReviewPackService(
            hands: context.read<SavedHandManagerService>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionNoteService()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionPinService()..load(),
        ),
        ChangeNotifierProvider(create: (_) => TrainingPackStorageService()..load()),
        ChangeNotifierProvider(create: (_) => TemplateStorageService()..load()),
        ChangeNotifierProvider(
          create: (context) => CategoryUsageService(
            templates: context.read<TemplateStorageService>(),
            packs: context.read<TrainingPackStorageService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => DailyHandService()..load()),
        ChangeNotifierProvider(create: (_) => DailyTargetService()..load()),
        ChangeNotifierProvider(create: (_) => DailyTipService()..load()),
        ChangeNotifierProvider(create: (_) => XPTrackerService()..load()),
        ChangeNotifierProvider(
          create: (context) => WeeklyChallengeService(
            stats: context.read<TrainingStatsService>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => StreakCounterService(
            stats: context.read<TrainingStatsService>(),
            target: context.read<DailyTargetService>(),
            xp: context.read<XPTrackerService>(),
          ),
        ),
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
          create: (context) => DailyReminderService(
            spot: context.read<SpotOfTheDayService>(),
            target: context.read<DailyTargetService>(),
            stats: context.read<TrainingStatsService>(),
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
          create: (context) => DrillSuggestionEngine(
            hands: context.read<SavedHandManagerService>(),
            packs: context.read<TrainingPackStorageService>(),
          ),
        ),
        Provider(create: (_) => EvaluationExecutorService()),
        Provider(create: (_) => CloudSyncService()),
        ChangeNotifierProvider(create: (_) => UserActionLogger()..load()),
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
