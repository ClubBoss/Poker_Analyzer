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
import 'screens/weakness_overview_screen.dart';
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
import 'services/goals_tracker_service.dart';
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
import 'app_providers.dart';
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
  auth = AuthService();
  rc = RemoteConfigService();
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
  ab = AbTestEngine(remote: rc);
  await ab.init();
  final cloud = CloudSyncService();
  final registry = ServiceRegistry();
  await AppBootstrap.init(cloud: cloud, registry: registry);
  final pluginManager = PluginManager();
  final loader = PluginLoader();
  final dir = Directory('plugins');
  if (await dir.exists()) {
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final plugin = await loader.loadFromFile(entity, pluginManager);
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
  packStorage = TrainingPackStorageService(cloud: cloud);
  await packStorage.load();
  packCloud = TrainingPackCloudSyncService();
  await packCloud.init();
  mistakeCloud = MistakePackCloudService();
  goalCloud = GoalProgressCloudService();
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
    _sync = AppBootstrap.sync!;
    context.read<UserActionLogger>().log('opened_app');
    unawaited(NotificationService.scheduleDailyReminder(context));
    unawaited(NotificationService.scheduleDailyProgress(context));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeResumeTraining();
      _maybeShowIntroOverlay();
    });
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
              Locale('es'),
              Locale('fr'),
              Locale('ru'),
              Locale('pt'),
              Locale('de'),
            ],
            routes: {
              WeaknessOverviewScreen.route: (_) => const WeaknessOverviewScreen(),
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
