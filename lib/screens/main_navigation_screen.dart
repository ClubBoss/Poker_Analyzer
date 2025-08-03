import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analyzer_tab.dart';
import 'spot_of_the_day_screen.dart';
import 'spot_of_the_day_history_screen.dart';
import 'settings_placeholder_screen.dart';
import 'insights_screen.dart';
import 'goal_overview_screen.dart';
import 'pack_overview_screen.dart';
import '../widgets/streak_banner.dart';
import '../widgets/motivation_card.dart';
import '../widgets/active_goals_card.dart';
import '../widgets/next_step_card.dart';
import '../widgets/suggested_drill_card.dart';
import '../widgets/next_best_step_banner.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/recent_unlocks_banner.dart';
import '../widgets/today_progress_banner.dart';
import '../widgets/pack_suggestion_banner.dart';
import '../widgets/broken_streak_banner.dart';
import '../widgets/smart_goal_banner.dart';
import '../widgets/goal_reminder_banner.dart';
import '../widgets/ev_goal_banner.dart';
import '../widgets/repeat_last_corrected_card.dart';
import '../widgets/repeat_corrected_drill_card.dart';
import '../widgets/streak_mini_card.dart';
import '../widgets/streak_chart.dart';
import '../widgets/continue_training_button.dart';
import '../widgets/spot_of_the_day_card.dart';
import '../widgets/decay_booster_dashboard_banner.dart';
import '../widgets/decay_booster_reminder_banner.dart';
import '../widgets/decay_booster_shortcut_banner.dart';
import '../widgets/decay_booster_queue_indicator.dart';
import '../widgets/decay_boosted_banner.dart';
import 'streak_history_screen.dart';
import '../services/user_action_logger.dart';
import '../services/daily_target_service.dart';
import '../widgets/streak_widget.dart';
import '../services/app_usage_tracker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/smart_inbox_debug_service.dart';
import '../widgets/resume_training_card.dart';
import '../services/ab_test_engine.dart';
import '../services/daily_training_reminder_service.dart';
import '../services/scheduled_training_launcher.dart';
import '../theme/app_colors.dart';
import 'plugin_manager_screen.dart';
import 'online_plugin_catalog_screen.dart';
import 'onboarding_screen.dart';
import 'ev_icm_analytics_screen.dart';
import 'ev_stats_screen.dart';
import 'progress_dashboard_screen.dart';
import 'skill_tree_track_list_screen.dart';
import 'position_tag_analytics_screen.dart';
import 'weakness_overview_screen.dart';
import 'learning_path_dashboard.dart';
import '../models/learning_path_template_v2.dart';
import 'notification_settings_screen.dart';
import 'dev_menu_screen.dart';
import 'shop_screen.dart';
import 'package:provider/provider.dart';
import '../utils/route_link.dart';
import '../services/learning_path_registry_service.dart';
import '../services/learning_path_orchestrator.dart';
import '../services/theory_pack_library_service.dart';
import 'learning_path_stage_preview_screen.dart';
import '../services/theory_lesson_tag_clusterer.dart';
import '../services/theory_cluster_summary_service.dart';
import 'theory_cluster_detail_screen.dart';
import 'package:collection/collection.dart';
import 'learning_path_screen_v2.dart';
import '../widgets/sync_status_widget.dart';
import '../user_preferences.dart';
import '../services/gift_drop_service.dart';
import '../services/session_streak_overlay_prompt_service.dart';
import '../services/overlay_decay_booster_orchestrator.dart';
import '../services/decay_badge_banner_controller.dart';
import 'dart:async';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  static const _indexKey = 'main_nav_index';
  int _currentIndex = 0;
  bool _simpleNavigation = false;
  bool _tutorialCompleted = false;
  late final Future<LearningPathTemplateV2> _pathFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final prefs = UserPreferences.instance;
    _simpleNavigation = prefs.simpleNavigation;
    _tutorialCompleted = prefs.tutorialCompleted;
    _pathFuture = _loadLearningPath();
    _loadIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
      _maybeShowTrainingReminder();
      _maybeLaunchScheduledTraining();
      _handleDeepLink();
      context.read<GiftDropService>().checkAndDropGift(context: context);
      context.read<SessionStreakOverlayPromptService>().run(context);
      context.read<DecayBadgeBannerController>().maybeShowStreakBadgeBanner(context);
    });
  }

  Future<void> _loadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    var idx = prefs.getInt(_indexKey) ?? 0;
    if (_simpleNavigation && idx > 3) idx = 0;
    setState(() => _currentIndex = idx);
  }

  Future<void> _saveIndex(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_indexKey, value);
  }

  Future<void> _maybeShowOnboarding() async {
    if (!_simpleNavigation || _tutorialCompleted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
    if (mounted) {
      setState(() =>
          _tutorialCompleted = UserPreferences.instance.tutorialCompleted);
    }
  }

  Future<void> _maybeShowTrainingReminder() async {
    await context
        .read<DailyTrainingReminderService>()
        .maybeShowReminder(context);
  }

  Future<void> _maybeLaunchScheduledTraining() async {
    await context.read<ScheduledTrainingLauncher>().launchNext();
  }

  Future<void> _handleDeepLink() async {
    final uri = Uri.base;
    // Handle direct link to a theory cluster detail.
    if (uri.path == '/theory/cluster') {
      final clusterId = uri.queryParameters['clusterId'];
      if (clusterId != null && clusterId.isNotEmpty) {
        final clusterer = TheoryLessonTagClusterer();
        final clusters = await clusterer.clusterLessons();
        final summaryService = TheoryClusterSummaryService();
        TheoryLessonCluster? matched;
        for (final c in clusters) {
          final summary = summaryService.generateSummary(c);
          if (summary.entryPointIds.contains(clusterId)) {
            matched = c;
            break;
          }
        }
        if (!mounted) return;
        if (matched != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TheoryClusterDetailScreen(cluster: matched!),
            ),
          );
        } else {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Cluster not found'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
      return;
    }

    final link = RouteLink.tryParse(uri);
    if (link == null) return;
    await LearningPathRegistryService.instance.loadAll();
    final template = LearningPathRegistryService.instance.findById(link.pathId);
    if (template == null) return;
    // New deep link to a specific stage preview.
    final segments = Uri.base.pathSegments;
    if (segments.length >= 4 &&
        segments.first == 'path' &&
        segments[2] == 'stage' &&
        link.stageId != null) {
      await TheoryPackLibraryService.instance.loadAll();
      final stage =
          template.stages.firstWhereOrNull((s) => s.id == link.stageId);
      if (stage == null || !mounted) return;
      await UserActionLogger.instance.log('deeplink_stage_preview');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LearningPathStagePreviewScreen(path: template, stage: stage),
        ),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPathScreen(
          template: template,
          highlightedStageId: link.stageId,
        ),
      ),
    );
  }

  Future<LearningPathTemplateV2> _loadLearningPath() async {
    await TheoryPackLibraryService.instance.loadAll();
    return LearningPathOrchestrator.instance.resolve();
  }

  Future<void> _setDailyGoal() async {
    final service = context.read<DailyTargetService>();
    final controller = TextEditingController(text: service.target.toString());
    final int? value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Daily Goal',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Hands',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final v = int.tryParse(controller.text);
                if (v != null && v > 0) {
                  Navigator.pop(context, v);
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (value != null) {
      await service.setTarget(value);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppUsageTracker.instance.markActive();
      _maybeShowTrainingReminder();
      _maybeLaunchScheduledTraining();
      unawaited(context
          .read<OverlayDecayBoosterOrchestrator>()
          .maybeShowIfIdle(context));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _home() {
    final ab = context.watch<AbTestEngine>();
    return Column(
      children: [
        ab.isVariant('resume_card', 'B')
            ? const ResumeTrainingCard()
            : const SizedBox.shrink(),
        Stack(
          children: const [
            ContinueTrainingButton(),
            Positioned(
              right: 24,
              top: 8,
              child: DecayBoosterQueueIndicator(),
            ),
          ],
        ),
        const DecayBoosterDashboardBanner(),
        const DecayBoostedBanner(),
        const DecayBoosterReminderBanner(),
        const DecayBoosterShortcutBanner(),
        const GoalReminderBanner(),
        const SmartGoalBanner(),
        const NextBestStepBanner(),
        const SpotOfTheDayCard(),
        const PackSuggestionBanner(),
        const StreakChart(),
        const TodayProgressBanner(),
        const StreakMiniCard(),
        TextButton(
          onPressed: _setDailyGoal,
          child: const Text('Set Daily Goal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StreakHistoryScreen()),
            );
          },
          child: const Text('View History'),
        ),
        const MotivationCard(),
        const ActiveGoalsCard(),
        const EVGoalBanner(),
        const RepeatLastCorrectedCard(),
        const RepeatCorrectedDrillCard(),
        const FeedbackBanner(),
        const RecentUnlocksBanner(),
        const NextStepCard(),
        const SuggestedDrillCard(),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, WeaknessOverviewScreen.route),
          icon: const Icon(Icons.analytics),
          label: const Text('Анализ ошибок'),
        ),
        const Expanded(child: AnalyzerTab()),
      ],
    );
  }

  Future<void> _showAboutDialog() async {
    final info = await PackageInfo.fromPlatform();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About'),
        content: GestureDetector(
          onLongPress: () {
            SmartInboxDebugService.instance.toggle();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Smart Inbox debug '
                  '${SmartInboxDebugService.instance.enabled ? 'enabled' : 'disabled'}',
                ),
              ),
            );
          },
          child: Text('Version ${info.version}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    UserActionLogger.instance.log('nav_$index');
    setState(() => _currentIndex = index);
    _saveIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _simpleNavigation
        ? [
            _home(),
            const SpotOfTheDayScreen(),
            const SettingsPlaceholderScreen(),
            const WeaknessOverviewScreen(),
            LearningPathDashboard(pathFuture: _pathFuture),
          ]
        : [
            _home(),
            const SpotOfTheDayScreen(),
            const SpotOfTheDayHistoryScreen(),
            const GoalOverviewScreen(),
            const PackOverviewScreen(),
            const InsightsScreen(),
            const SettingsPlaceholderScreen(),
            LearningPathDashboard(pathFuture: _pathFuture),
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker AI Analyzer'),
        actions: [
          const StreakWidget(),
          SyncStatusIcon.of(context),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPlaceholderScreen(),
                    ),
                  );
                  break;
                case 'plugins':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PluginManagerScreen(),
                    ),
                  );
                  break;
                case 'community_plugins':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnlinePluginCatalogScreen(),
                    ),
                  );
                  break;
                case 'onboarding':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                  break;
                case 'evicm':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EvIcmAnalyticsScreen(),
                    ),
                  );
                  break;
                case 'evstats':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EvStatsScreen(),
                    ),
                  );
                  break;
                case 'dashboard':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProgressDashboardScreen(),
                    ),
                  );
                  break;
                case 'tracks':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SkillTreeTrackListScreen(),
                    ),
                  );
                  break;
                case 'pos_tag':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PositionTagAnalyticsScreen(),
                    ),
                  );
                  break;
                case 'dev':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DevMenuScreen(),
                    ),
                  );
                  break;
                case 'notifications':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                  break;
                case 'shop':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopScreen()),
                  );
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'settings', child: Text('⚙️ Settings')),
              PopupMenuItem(
                  value: 'notifications', child: Text('🔔 Notifications')),
              PopupMenuItem(value: 'plugins', child: Text('🧩 Plugins')),
              PopupMenuItem(
                  value: 'community_plugins', child: Text('🌐 Community')),
              PopupMenuItem(value: 'onboarding', child: Text('📖 Обучение')),
              PopupMenuItem(value: 'evicm', child: Text('EV/ICM')),
              PopupMenuItem(value: 'evstats', child: Text('EV Stats')),
              PopupMenuItem(value: 'pos_tag', child: Text('Позиции/Теги')),
              PopupMenuItem(value: 'tracks', child: Text('🎓 Треки')),
              PopupMenuItem(value: 'dashboard', child: Text('📈 Dashboard')),
              PopupMenuItem(value: 'dev', child: Text('Dev Menu')),
              PopupMenuItem(value: 'shop', child: Text('🛒 Shop')),
              PopupMenuItem(value: 'about', child: Text('About')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StreakBanner(),
          BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.greenAccent,
            unselectedItemColor: Colors.white70,
            currentIndex: _currentIndex,
            onTap: _onTap,
            type: BottomNavigationBarType.fixed,
            items: _simpleNavigation
                ? const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assessment),
                      label: 'Раздачи',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.today),
                      label: 'Спот дня',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.more_horiz),
                      label: 'Ещё',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.analytics_outlined),
                      label: 'Аналитика',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                  ]
                : const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assessment),
                      label: 'Раздачи',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.today),
                      label: 'Спот дня',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history),
                      label: 'История',
                    ),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.flag), label: 'Goal'),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.backpack),
                      label: 'My Packs',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.insights),
                      label: '📊 Insights',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.more_horiz),
                      label: 'Ещё',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}
