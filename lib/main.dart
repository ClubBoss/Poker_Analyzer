// lib/main.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/plugin_runtime.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/weakness_overview_screen.dart';
import 'screens/master_mode_screen.dart';
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
import 'services/daily_hand_service.dart';
import 'services/spot_of_the_day_service.dart';
import 'services/action_sync_service.dart';
import 'services/folded_players_service.dart';
import 'services/all_in_players_service.dart';
import 'services/user_preferences_service.dart';
import 'services/tag_service.dart';
import 'services/tag_cache_service.dart';
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
import 'services/user_goal_engine.dart';
import 'services/streak_service.dart';
import 'services/achievement_service.dart';
import 'services/reminder_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/next_step_engine.dart';
import 'services/drill_suggestion_engine.dart';
import 'services/weak_spot_recommendation_service.dart';
import 'services/daily_focus_recap_service.dart';
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
import 'services/reward_service.dart';
import 'services/weekly_challenge_service.dart';
import 'services/daily_challenge_service.dart';
import 'services/daily_challenge_notification_service.dart';
import 'services/daily_goals_service.dart';
import 'services/session_log_service.dart';
import 'services/category_usage_service.dart';
import 'services/goal_sync_service.dart';
import 'user_preferences.dart';
import 'services/user_action_logger.dart';
import 'services/mistake_review_pack_service.dart';
import 'services/mistake_streak_service.dart';
import 'services/mistake_hint_service.dart';
import 'services/dynamic_pack_adjustment_service.dart';
import 'services/remote_config_service.dart';
import 'services/theme_service.dart';
import 'services/ab_test_engine.dart';
import 'services/suggestion_banner_ab_test_service.dart';
import 'services/asset_sync_service.dart';
import 'services/favorite_pack_service.dart';
import 'services/evaluation_settings_service.dart';
import 'widgets/sync_status_widget.dart';
import 'widgets/first_launch_tutorial.dart';
import 'screens/onboarding_screen.dart';
import 'onboarding/onboarding_flow_manager.dart';
import 'app_bootstrap.dart';
import 'app_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'helpers/training_pack_storage.dart';
import 'screens/v2/training_pack_play_screen.dart';
import 'core/error_logger.dart';
import 'services/pinned_pack_service.dart';
import 'services/training_pack_template_service.dart';
import 'services/training_pack_stats_service.dart';
import 'services/learning_path_summary_cache.dart';
import 'services/learning_path_reminder_engine.dart';
import 'services/daily_app_check_service.dart';
import 'screens/training_session_screen.dart';
import 'screens/empty_training_screen.dart';
import 'services/app_init_service.dart';
import 'services/suggested_pack_push_service.dart';
import 'services/lesson_path_reminder_scheduler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  auth = AuthService();
  rc = RemoteConfigService();
  if (!CloudSyncService.isLocal) {
    await Firebase.initializeApp();
    await NotificationService.init();
    await DailyChallengeNotificationService.init();
    await rc.load();
    if (!auth.isSignedIn) {
      final uid = await auth.signInAnonymously();
      if (uid != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('anon_uid_log', uid);
      }
    }
  }
  ab = AbTestEngine(remote: rc);
  await ab.init();
  final cloud = CloudSyncService();
  final runtime = PluginRuntime();
  await AppBootstrap.init(cloud: cloud, runtime: runtime);
  packStorage = TrainingPackStorageService(cloud: cloud);
  await packStorage.load();
  await packStorage.loadBuiltInPacks();
  packCloud = TrainingPackCloudSyncService();
  await packCloud.init();
  mistakeCloud = MistakePackCloudService();
  goalCloud = GoalProgressCloudService();
  goalSync = GoalSyncService();
  templateStorage = TrainingPackTemplateStorageService(
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
  await SuggestionBannerABTestService.instance.init();
  tagCache = TagCacheService();
  await tagCache.load();
  unawaited(SuggestedPackPushService.instance.schedulePushReminder());
  await AppInitService.instance.init();
  runApp(
    MultiProvider(
      providers: buildAppProviders(cloud),
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

  Future<void> _maybeShowIntroTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    var done = true;
    for (int i = 0; i < 3; i++) {
      if (prefs.getBool('intro_step_$i') != true) {
        done = false;
        break;
      }
    }
    if (done) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    showFirstLaunchTutorial(ctx);
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

  Future<void> _maybeStartOnboarding() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    await OnboardingFlowManager.instance.maybeStart(ctx);
  }

  @override
  void initState() {
    super.initState();
    _sync = AppBootstrap.sync!;
    context.read<UserActionLogger>().log('opened_app');
    unawaited(NotificationService.scheduleDailyReminder(context));
    unawaited(() async {
      final t = await DailyChallengeNotificationService.getScheduledTime();
      await DailyChallengeNotificationService.scheduleDailyReminder(time: t);
    }());
    unawaited(NotificationService.scheduleDailyProgress(context));
    unawaited(() async {
      final t = await LessonPathReminderScheduler.instance.getScheduledTime();
      if (t != null) {
        await LessonPathReminderScheduler.instance.scheduleReminder(time: t);
      }
    }());
    NotificationService.startRecommendedPackTask(context);
    unawaited(context.read<LearningPathSummaryCache>().refresh());
    unawaited(context.read<DailyAppCheckService>().run(context));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartPinnedTraining();
      _maybeResumeTraining();
      _maybeShowIntroTutorial();
      _maybeStartOnboarding();
    });
  }

  Future<void> _maybeStartPinnedTraining() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final templates = TrainingPackTemplateService.getAllTemplates(ctx);
    final prefs = await SharedPreferences.getInstance();
    final valid = templates
        .where((t) => !(prefs.getBool('completed_tpl_${t.id}') ?? false))
        .toList();
    if (valid.isEmpty) {
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const EmptyTrainingScreen()),
      );
      return;
    }
    final service = ctx.read<PinnedPackService>();
    final pinned = valid.firstWhereOrNull((t) => service.isPinned(t.id));
    if (pinned == null) return;
    final completed = prefs.getBool('completed_tpl_${pinned.id}') ?? false;
    final stat = await TrainingPackStatsService.getStats(pinned.id);
    final idx = stat?.lastIndex ?? 0;
    if (completed && idx >= pinned.spots.length - 1) {
      final rec = await ctx
          .read<PersonalRecommendationService>()
          .getTopRecommended();
      if (rec == null) return;
      await ctx.read<TrainingSessionService>().startSession(rec);
    } else {
      await ctx.read<TrainingSessionService>().startSession(pinned);
    }
    if (!mounted) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.pop(ctx);
    Navigator.pushReplacement(
      ctx,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const TrainingSessionScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    AppBootstrap.dispose();
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
            theme: context.read<ThemeService>().lightTheme,
            darkTheme: context.read<ThemeService>().darkTheme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
              Locale('fr'),
              Locale('ru'),
              Locale('pt'),
              Locale('de'),
            ],
            routes: {
              WeaknessOverviewScreen.route: (_) =>
                  const WeaknessOverviewScreen(),
              MasterModeScreen.route: (_) => const MasterModeScreen(),
            },
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
