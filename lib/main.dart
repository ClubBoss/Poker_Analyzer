// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/plugin_runtime.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/weakness_overview_screen.dart';
import 'screens/master_mode_screen.dart';
import 'screens/goal_center_screen.dart';
import 'screens/achievements_dashboard_screen.dart';
import 'screens/goal_insights_screen.dart';
import 'screens/memory_insights_screen.dart';
import 'screens/decay_dashboard_screen.dart';
import 'screens/decay_heatmap_screen.dart';
import 'screens/decay_stats_dashboard_screen.dart';
import 'screens/decay_analytics_screen.dart';
import 'screens/decay_adaptation_insight_screen.dart';
import 'screens/skill_tree_learning_map_screen.dart';
import 'screens/skill_tree_track_map_screen.dart';
import 'screens/skill_tree_track_list_screen.dart';
import 'screens/reward_gallery_screen.dart';
import 'services/training_pack_storage_service.dart';
import 'services/training_pack_cloud_sync_service.dart';
import 'services/mistake_pack_cloud_service.dart';
import 'services/training_pack_template_storage_service.dart';
import 'services/goal_progress_cloud_service.dart';
import 'services/tag_cache_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/auth_service.dart';
import 'services/connectivity_sync_controller.dart';
import 'services/training_session_service.dart';
import 'services/training_reminder_push_service.dart';
import 'services/goal_reengagement_service.dart';
import 'services/personal_recommendation_service.dart';
import 'services/notification_service.dart';
import 'services/daily_challenge_notification_service.dart';
import 'services/goal_sync_service.dart';
import 'services/user_action_logger.dart';
import 'services/mistake_hint_service.dart';
import 'services/remote_config_service.dart';
import 'services/theme_service.dart';
import 'services/app_usage_tracker.dart';
import 'services/ab_test_engine.dart';
import 'services/suggestion_banner_ab_test_service.dart';
import 'services/asset_sync_service.dart';
import 'services/evaluation_settings_service.dart';
import 'widgets/sync_status_widget.dart';
import 'widgets/first_launch_tutorial.dart';
import 'onboarding/onboarding_flow_manager.dart';
import 'app_bootstrap.dart';
import 'app_providers.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:collection/collection.dart';
import 'helpers/training_pack_storage.dart';
import 'screens/v2/training_pack_play_screen.dart';
import 'core/error_logger.dart';
import 'services/pinned_pack_service.dart';
import 'services/training_pack_template_service.dart';
import 'services/training_pack_stats_service.dart';
import 'services/learning_path_summary_cache.dart';
import 'services/daily_app_check_service.dart';
import 'services/skill_loss_overlay_prompt_service.dart';
import 'services/overlay_booster_manager.dart';
import 'services/overlay_decay_booster_orchestrator.dart';
import 'services/decay_streak_overlay_prompt_service.dart';
import 'screens/training_session_screen.dart';
import 'screens/empty_training_screen.dart';
import 'models/v2/training_pack_v2.dart';
import 'models/v2/training_pack_template_v2.dart';
import 'services/app_init_service.dart';
import 'services/suggested_pack_push_service.dart';
import 'services/lesson_path_reminder_scheduler.dart';
import 'services/decay_reminder_scheduler.dart';
import 'services/decay_booster_notification_service.dart';
import 'services/decay_booster_cron_job.dart';
import 'services/theory_lesson_notification_scheduler.dart';
import 'services/booster_recall_decay_cleaner.dart';
import 'services/pinned_comeback_nudge_service.dart';
import 'route_observer.dart';
import 'services/shared_preferences_service.dart';

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
        await SharedPreferencesService.instance.init();
        await SharedPreferencesService.instance
            .setString('anon_uid_log', uid);
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
  unawaited(DecayBoosterNotificationService.instance.init());
  unawaited(DecayReminderScheduler.instance.register());
  unawaited(DecayReminderScheduler.instance.runIfNeeded());
  unawaited(DecayBoosterCronJob.instance.start());
  unawaited(PinnedComebackNudgeService.instance.start());
  await BoosterRecallDecayCleaner.instance.init();
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
        12) {
      return;
    }
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
    AppUsageTracker.instance.markActive();
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
    unawaited(TrainingReminderPushService.instance.reschedule(
      reengagement: context.read<GoalReengagementService>(),
      sessions: context.read<TrainingSessionService>(),
    ));
    unawaited(context.read<SkillLossOverlayPromptService>().run(context));
    unawaited(context
        .read<OverlayDecayBoosterOrchestrator>()
        .maybeShowIfIdle(context));
    unawaited(context.read<OverlayBoosterManager>().onAfterXpScreen());
    unawaited(context
        .read<DecayStreakOverlayPromptService>()
        .maybeShowOverlayIfStreakAtRisk(context));
    unawaited(
      TheoryLessonNotificationScheduler.instance.scheduleReminderIfNeeded(),
    );
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
      final rec =
          await ctx.read<PersonalRecommendationService>().getTopRecommended();
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

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    if (settings.name == TrainingSessionScreen.route) {
      final arg = settings.arguments;
      if (arg is TrainingPackV2) {
        return MaterialPageRoute(
          builder: (_) => TrainingSessionScreen(pack: arg),
        );
      } else if (arg is TrainingPackTemplateV2) {
        final pack = TrainingPackV2.fromTemplate(arg, arg.id);
        return MaterialPageRoute(
          builder: (_) => TrainingSessionScreen(pack: pack),
        );
      }
    }
    if (settings.name == SkillTreeLearningMapScreen.route &&
        settings.arguments is String) {
      final trackId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => SkillTreeLearningMapScreen(trackId: trackId),
      );
    }
    return null;
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
            navigatorObservers: [routeObserver],
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
            onGenerateRoute: _onGenerateRoute,
            routes: {
              WeaknessOverviewScreen.route: (_) =>
                  const WeaknessOverviewScreen(),
              MasterModeScreen.route: (_) => const MasterModeScreen(),
              GoalCenterScreen.route: (_) => const GoalCenterScreen(),
              AchievementsDashboardScreen.route: (_) =>
                  const AchievementsDashboardScreen(),
              GoalInsightsScreen.route: (_) => const GoalInsightsScreen(),
              MemoryInsightsScreen.route: (_) => const MemoryInsightsScreen(),
              DecayDashboardScreen.route: (_) => const DecayDashboardScreen(),
              DecayHeatmapScreen.route: (_) => const DecayHeatmapScreen(),
              DecayStatsDashboardScreen.route: (_) =>
                  const DecayStatsDashboardScreen(),
              DecayAnalyticsScreen.route: (_) => const DecayAnalyticsScreen(),
              DecayAdaptationInsightScreen.route: (_) =>
                  const DecayAdaptationInsightScreen(),
              SkillTreeTrackMapScreen.route: (_) =>
                  const SkillTreeTrackMapScreen(),
              SkillTreeTrackListScreen.route: (_) =>
                  const SkillTreeTrackListScreen(),
              RewardGalleryScreen.route: (_) => const RewardGalleryScreen(),
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
