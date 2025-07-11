// lib/main.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:poker_analyzer/plugins/plugin_loader.dart';
import 'package:poker_analyzer/plugins/plugin_manager.dart';
import 'services/service_registry.dart';
import 'screens/main_navigation_screen.dart';
import 'services/saved_hand_storage_service.dart';
import 'services/saved_hand_manager_service.dart';
import 'services/session_note_service.dart';
import 'services/session_pin_service.dart';
import 'services/session_manager.dart';
import 'services/training_pack_storage_service.dart';
import 'services/training_pack_cloud_sync_service.dart';
import 'services/mistake_pack_cloud_service.dart';
import 'services/template_storage_service.dart';
import 'services/training_pack_template_storage_service.dart';
import 'services/adaptive_training_service.dart';
import 'services/goal_progress_cloud_service.dart';
import 'services/xp_tracker_cloud_service.dart';
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
import 'services/auth_service.dart';
import 'services/cloud_training_history_service.dart';
import 'services/connectivity_sync_controller.dart';
import 'services/training_spot_storage_service.dart';
import 'services/evaluation_executor_service.dart';
import 'services/training_stats_service.dart';
import 'services/streak_counter_service.dart';
import 'services/training_session_service.dart';
import 'services/hand_analyzer_service.dart';
import 'services/achievement_engine.dart';
import 'services/goal_engine.dart';
import 'services/streak_service.dart';
import 'services/reminder_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/next_step_engine.dart';
import 'services/drill_suggestion_engine.dart';
import 'services/weak_spot_recommendation_service.dart';
import 'services/player_progress_service.dart';
import 'services/player_style_service.dart';
import 'services/player_style_forecast_service.dart';
import 'services/real_time_stack_range_service.dart';
import 'services/progress_forecast_service.dart';
import 'services/personal_recommendation_service.dart';
import 'services/feedback_service.dart';
import 'services/drill_history_service.dart';
import 'services/mixed_drill_history_service.dart';
import 'services/hand_analysis_history_service.dart';
import 'services/training_pack_play_controller.dart';
import 'services/notification_service.dart';
import 'services/daily_target_service.dart';
import 'services/daily_tip_service.dart';
import 'services/xp_tracker_service.dart';
import 'services/weekly_challenge_service.dart';
import 'services/daily_challenge_service.dart';
import 'services/daily_goals_service.dart';
import 'services/session_log_service.dart';
import 'services/category_usage_service.dart';
import 'user_preferences.dart';
import 'services/user_action_logger.dart';
import 'services/mistake_review_pack_service.dart';
import 'services/mistake_streak_service.dart';
import 'services/mistake_hint_service.dart';
import 'services/dynamic_pack_adjustment_service.dart';
import 'services/remote_config_service.dart';
import 'services/theme_service.dart';
import 'services/ab_test_engine.dart';
import 'services/asset_sync_service.dart';
import 'services/favorite_pack_service.dart';
import 'services/evaluation_settings_service.dart';
import 'widgets/sync_status_widget.dart';
import 'widgets/first_launch_overlay.dart';
import 'screens/onboarding_screen.dart';
import 'app_bootstrap.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'helpers/training_pack_storage.dart';
import 'screens/v2/training_pack_play_screen.dart';
import 'core/error_logger.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  final rc = RemoteConfigService();
  if (!CloudSyncService.isLocal) {
    await Firebase.initializeApp();
    await NotificationService.init();
    await rc.load();
    if (!auth.isSignedIn) {
      final uid = await auth.signInAnonymously();
      if (uid != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('anon_uid_log', uid);
      }
    }
  }
  final ab = AbTestEngine(remote: rc);
  await ab.init();
  final cloud = CloudSyncService();
  await AppBootstrap.init(cloud: cloud);
  final registry = ServiceRegistry();
  final pluginManager = PluginManager();
  final loader = PluginLoader();
  final dir = Directory('plugins');
  if (await dir.exists()) {
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final plugin = await loader.loadFromFile(entity);
        if (plugin != null) {
          pluginManager.load(plugin);
        }
      }
    }
  }
  for (final p in loader.loadBuiltInPlugins()) {
    pluginManager.load(p);
  }
  pluginManager.initializeAll(registry);
  final packStorage = TrainingPackStorageService(cloud: cloud);
  await packStorage.load();
  final packCloud = TrainingPackCloudSyncService();
  await packCloud.init();
  final mistakeCloud = MistakePackCloudService();
  final goalCloud = GoalProgressCloudService();
  final xpCloud = XPTrackerCloudService();
  final templateStorage = TrainingPackTemplateStorageService(
    cloud: packCloud,
    goals: goalCloud,
  );
  await templateStorage.load();
  await packCloud.syncDown(packStorage);
  await packCloud.syncDownTemplates(templateStorage);
  await packCloud.syncDownStats();
  await packCloud.syncUpTemplates(templateStorage);
  unawaited(
    AssetSyncService.instance.syncIfNeeded().catchError(
      (e, st) => ErrorLogger.instance.logError('Asset sync failed', e, st),
    ),
  );
  await EvaluationSettingsService.instance.load();
  await MistakeHintService.instance.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<RemoteConfigService>.value(value: rc),
        ChangeNotifierProvider<AbTestEngine>.value(value: ab),
        ChangeNotifierProvider(create: (_) => ThemeService()..load()),
        Provider<CloudSyncService>.value(value: cloud),
        Provider(create: (_) => CloudTrainingHistoryService()..init()),
        ChangeNotifierProvider(
          create: (context) => TrainingSpotStorageService(
            cloud: context.read<CloudSyncService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TrainingStatsService(cloud: context.read<CloudSyncService>())
                ..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SavedHandStorageService(cloud: context.read<CloudSyncService>())
                ..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => SavedHandManagerService(
            storage: context.read<SavedHandStorageService>(),
            cloud: context.read<CloudSyncService>(),
            stats: context.read<TrainingStatsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PlayerProgressService(hands: context.read<SavedHandManagerService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PlayerStyleService(hands: context.read<SavedHandManagerService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PlayerStyleForecastService(hands: context.read<SavedHandManagerService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => RealTimeStackRangeService(
            forecast: context.read<PlayerStyleForecastService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProgressForecastService(hands: context.read<SavedHandManagerService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => MistakeReviewPackService(
            hands: context.read<SavedHandManagerService>(),
            cloud: mistakeCloud,
          )..load(),
        ),
        Provider(
          create: (context) => DynamicPackAdjustmentService(
            mistakes: context.read<MistakeReviewPackService>(),
            eval: EvaluationExecutorService(),
            hands: context.read<SavedHandManagerService>(),
            progress: context.read<PlayerProgressService>(),
            forecast: context.read<PlayerStyleForecastService>(),
            style: context.read<PlayerStyleService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MistakeStreakService()..load(),
        ),
        ChangeNotifierProvider(
            create: (context) =>
                SessionNoteService(cloud: context.read<CloudSyncService>())
                  ..load()),
        ChangeNotifierProvider(
            create: (context) =>
                SessionPinService(cloud: context.read<CloudSyncService>())
                  ..load()),
        ChangeNotifierProvider<TrainingPackStorageService>.value(
          value: packStorage,
        ),
        Provider<TrainingPackCloudSyncService>.value(value: packCloud),
        Provider<MistakePackCloudService>.value(value: mistakeCloud),
        Provider<XPTrackerCloudService>.value(value: xpCloud),
        ChangeNotifierProvider(create: (_) => TemplateStorageService()..load()),
        ChangeNotifierProvider(create: (_) => HandAnalysisHistoryService()..load()),
        ChangeNotifierProvider(
          create: (context) => AdaptiveTrainingService(
            templates: context.read<TemplateStorageService>(),
            mistakes: context.read<MistakeReviewPackService>(),
            hands: context.read<SavedHandManagerService>(),
            history: context.read<HandAnalysisHistoryService>(),
            xp: context.read<XPTrackerService>(),
            forecast: context.read<ProgressForecastService>(),
            style: context.read<PlayerStyleService>(),
            styleForecast: context.read<PlayerStyleForecastService>(),
          ),
        ),
        ChangeNotifierProvider<TrainingPackTemplateStorageService>.value(
          value: templateStorage,
        ),
        Provider<FavoritePackService>.value(value: FavoritePackService.instance),
        ChangeNotifierProvider(
          create: (context) => CategoryUsageService(
            templates: context.read<TemplateStorageService>(),
            packs: context.read<TrainingPackStorageService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => DailyHandService()..load()),
        ChangeNotifierProvider(create: (_) => DailyTargetService()..load()),
        ChangeNotifierProvider(create: (_) => DailyTipService()..load()),
        ChangeNotifierProvider(create: (_) => XPTrackerService(cloud: xpCloud)..load()),
        ChangeNotifierProvider(
          create: (context) => DailyChallengeService(
            adaptive: context.read<AdaptiveTrainingService>(),
            templates: context.read<TemplateStorageService>(),
            xp: context.read<XPTrackerService>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => WeeklyChallengeService(
            stats: context.read<TrainingStatsService>(),
            xp: context.read<XPTrackerService>(),
            packs: context.read<TrainingPackStorageService>(),
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
        ChangeNotifierProvider(
          create: (context) => DailyGoalsService(
            stats: context.read<TrainingStatsService>(),
            hands: context.read<SavedHandManagerService>(),
          )..load(),
        ),
        ChangeNotifierProvider(create: (_) => AllInPlayersService()),
        ChangeNotifierProvider(create: (_) => FoldedPlayersService()),
        ChangeNotifierProvider(
          create: (context) => ActionSyncService(
            foldedPlayers: context.read<FoldedPlayersService>(),
            allInPlayers: context.read<AllInPlayersService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final service = UserPreferencesService(
              cloud: context.read<CloudSyncService>(),
            );
            UserPreferences.init(service);
            service.load();
            return service;
          },
        ),
        ChangeNotifierProvider(create: (_) => TagService()..load()),
        ChangeNotifierProvider(create: (_) => IgnoredMistakeService()..load()),
        ChangeNotifierProvider(create: (_) => GoalsService()..load()),
        ChangeNotifierProvider(
          create: (context) => StreakService(
            cloud: context.read<CloudSyncService>(),
            xp: context.read<XPTrackerService>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AchievementEngine(stats: context.read<TrainingStatsService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              GoalEngine(stats: context.read<TrainingStatsService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PersonalRecommendationService(
            achievements: context.read<AchievementEngine>(),
            adaptive: context.read<AdaptiveTrainingService>(),
            weak: context.read<WeakSpotRecommendationService>(),
            style: context.read<PlayerStyleService>(),
            forecast: context.read<PlayerStyleForecastService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ReminderService(
            context: context,
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
            goals: context.read<DailyGoalsService>(),
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
        ChangeNotifierProvider(
          create: (context) => WeakSpotRecommendationService(
            hands: context.read<SavedHandManagerService>(),
            progress: context.read<PlayerProgressService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FeedbackService(
            achievements: context.read<AchievementEngine>(),
            progress: context.read<PlayerProgressService>(),
            next: context.read<NextStepEngine>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => DrillHistoryService()..load()),
        ChangeNotifierProvider(
          create: (_) => MixedDrillHistoryService()..load(),
        ),
        Provider(create: (_) => const HandAnalyzerService()),
        ChangeNotifierProvider(
          create: (_) => TrainingPackPlayController()..load(),
        ),
        ChangeNotifierProvider(create: (_) => TrainingSessionService()..load()),
        Provider(
          create: (context) => SessionManager(
            hands: context.read<SavedHandManagerService>(),
            notes: context.read<SessionNoteService>(),
            sessions: context.read<TrainingSessionService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SessionLogService(
            sessions: context.read<TrainingSessionService>(),
            cloud: context.read<CloudSyncService>(),
          )..load(),
        ),
        Provider(create: (_) => EvaluationExecutorService()),
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
  late final ConnectivitySyncController _sync;

  Future<void> _maybeShowIntroOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seen_intro_overlay') == true) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    showFirstLaunchOverlay(ctx, () async {
      final p = await SharedPreferences.getInstance();
      await p.setBool('seen_intro_overlay', true);
    });
  }


  Future<void> _maybeResumeTraining() async {
    final prefs = await SharedPreferences.getInstance();
    String? id;
    int ts = 0;
    for (final k in prefs.getKeys()) {
      if (k.startsWith('tpl_prog_')) {
        final pack = k.substring(9);
        final t = prefs.getInt('tpl_ts_$pack') ?? 0;
        if (t > ts) {
          ts = t;
          id = pack;
        }
      }
    }
    if (id == null || ts == 0) return;
    if (DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(ts))
            .inHours >
        12)
      return;
    final templates = await TrainingPackStorage.load();
    final tpl = templates.firstWhereOrNull((t) => t.id == id);
    if (tpl == null) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text('Resume "${tpl.name}"?'),
        content: const Text('You were in the middle of a training pack.'),
        actions: [
          TextButton(
            onPressed: () {
              if (dCtx.mounted) Navigator.pop(dCtx, false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              if (dCtx.mounted) Navigator.pop(dCtx, true);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => TrainingPackPlayScreen(template: tpl, original: tpl),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sync = ConnectivitySyncController(cloud: context.read<CloudSyncService>());
    context.read<UserActionLogger>().log('opened_app');
    unawaited(NotificationService.scheduleDailyReminder(context));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeResumeTraining();
      _maybeShowIntroOverlay();
    });
  }

  @override
  void dispose() {
    _sync.dispose();
    context.read<CloudSyncService>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SyncStatusWidget(
      sync: _sync,
      cloud: context.read<CloudSyncService>(),
      child: Builder(
        builder: (context) {
          final theme = context.watch<ThemeService>().mode;
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Poker AI Analyzer',
            debugShowCheckedModeBanner: false,
            themeMode: theme,
            theme: ThemeData.light().copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
              textTheme: ThemeData.light().textTheme.apply(
                fontFamily: 'Roboto',
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
              scaffoldBackgroundColor: Colors.black,
              textTheme: ThemeData.dark().textTheme.apply(
                fontFamily: 'Roboto',
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ru'),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) return const Locale('ru');
              for (final l in supportedLocales) {
                if (l.languageCode == locale.languageCode) return l;
              }
              return const Locale('ru');
            },
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
