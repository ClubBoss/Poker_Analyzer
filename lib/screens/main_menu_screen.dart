import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player_input_screen.dart';
import 'saved_hands_screen.dart';
import 'training_packs_screen.dart';
import 'all_sessions_screen.dart';
import 'cloud_training_history_screen.dart';
import 'my_training_history_screen.dart';
import 'cloud_training_history_service_screen.dart';
import 'player_zone_demo_screen.dart';
import 'poker_table_demo_screen.dart';
import 'hand_editor_screen.dart';
import 'settings_screen.dart';
import '../utils/responsive.dart';
import 'remote_sessions_screen.dart';
import 'global_evaluation_screen.dart';
import 'daily_hand_screen.dart';
import 'spot_of_the_day_screen.dart';
import 'create_pack_screen.dart';
import 'edit_pack_screen.dart';
import 'my_training_packs_screen.dart';
import 'training_screen.dart';
import 'start_training_from_pack_screen.dart';
import '../helpers/training_onboarding.dart';
import 'package:provider/provider.dart';
import '../services/hand_history_file_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/saved_hand_export_service.dart';
import '../services/training_spot_of_day_service.dart';
import '../models/training_spot.dart';
import '../services/user_preferences_service.dart';
import '../main_demo.dart';
import '../widgets/training_spot_preview.dart';
import '../tutorial/tutorial_flow.dart';
import '../tutorial/tutorial_completion_screen.dart';
import 'onboarding_screen.dart';
import 'training_history_screen.dart';
import 'session_stats_screen.dart';
import 'training_stats_screen.dart';
import 'progress_screen.dart';
import 'progress_overview_screen.dart';
import 'progress_history_screen.dart';
import 'drill_history_screen.dart';
import 'memory_insights_screen.dart';
import 'decay_dashboard_screen.dart';
import 'decay_heatmap_screen.dart';
import 'decay_stats_dashboard_screen.dart';
import 'decay_adaptation_insight_screen.dart';
import '../services/streak_service.dart';
import 'goals_overview_screen.dart';
import 'mistake_repeat_screen.dart';
import 'quick_hand_analysis_screen.dart';
import 'hand_analysis_history_screen.dart';
import 'achievements_screen.dart';
import 'reward_gallery_screen.dart';
import '../services/goals_service.dart';
import '../widgets/focus_of_the_week_card.dart';
import '../widgets/sync_status_widget.dart';
import 'weakness_overview_screen.dart';
import 'training_home_screen.dart';
import 'ready_to_train_screen.dart';
import '../widgets/lesson_suggestion_banner.dart';
import '../widgets/smart_decay_goal_banner.dart';
import '../widgets/smart_mistake_goal_banner.dart';
import '../widgets/recovery_prompt_banner.dart';
import '../widgets/user_goal_reengagement_banner.dart';
import '../widgets/smart_recap_suggestion_banner.dart';
import '../widgets/recap_banner_widget.dart';
import '../widgets/goal_suggestion_row.dart';
import '../services/smart_goal_aggregator_service.dart';
import '../models/goal_recommendation.dart';
import '../widgets/skill_tree_main_menu_entry.dart';
import '../utils/snackbar_util.dart';

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Key? key;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.key,
  });
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _demoMode = false;
  TrainingSpot? _spotOfDay;
  final GlobalKey _trainingButtonKey = GlobalKey();
  final GlobalKey _newHandButtonKey = GlobalKey();
  final GlobalKey _historyButtonKey = GlobalKey();
  bool _tutorialCompleted = false;
  bool _showStreakPopup = false;
  bool _suggestedDismissed = false;
  DateTime? _dismissedDate;
  static const _dismissedKey = 'suggested_weekly_dismissed_date';
  List<GoalRecommendation> _goalSuggestions = [];
  bool _loadingSuggestions = true;

  Widget _buildStreakIndicator(BuildContext context) {
    final streak = context.watch<StreakService>().count;
    if (streak <= 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              'Стрик: $streak дней',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final prefs = context.read<UserPreferencesService>();
    _demoMode = prefs.demoMode;
    _tutorialCompleted = prefs.tutorialCompleted;
    context.read<StreakService>().addListener(_onStreakChanged);
    _loadSpot();
    _loadDismissed();
    _loadGoalSuggestions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StreakService>().updateStreak();
        context.read<GoalsService>().ensureDailyGoal();
        _maybeShowOnboarding();
      }
    });
  }

  Future<void> _loadSpot() async {
    const service = TrainingSpotOfDayService();
    final spot = await service.getSpot();
    if (mounted) {
      setState(() => _spotOfDay = spot);
    }
  }

  Future<void> _loadGoalSuggestions() async {
    final service = SmartGoalAggregatorService();
    final list = await service.getRecommendations();
    if (!mounted) return;
    setState(() {
      _goalSuggestions = list;
      _loadingSuggestions = false;
    });
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_dismissedKey);
    if (!mounted) return;
    if (str != null) {
      final dt = DateTime.tryParse(str);
      if (dt != null && DateTime.now().difference(dt).inDays < 7) {
        setState(() {
          _suggestedDismissed = true;
          _dismissedDate = dt;
        });
      } else {
        await prefs.remove(_dismissedKey);
      }
    }
  }

  void _maybeShowOnboarding() {
    if (context.read<UserPreferencesService>().tutorialCompleted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      if (mounted) {
        setState(() => _tutorialCompleted =
            context.read<UserPreferencesService>().tutorialCompleted);
      }
    });
  }

  Future<void> _dismissSuggestedBanner() async {
    final now = DateTime.now();
    setState(() {
      _suggestedDismissed = true;
      _dismissedDate = now;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedKey, now.toIso8601String());
  }

  Future<void> _clearDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedKey);
    if (!mounted) return;
    setState(() {
      _suggestedDismissed = false;
      _dismissedDate = null;
    });
  }

  void _onStreakChanged() {
    final service = context.read<StreakService>();
    if (service.consumeIncreaseFlag()) {
      setState(() => _showStreakPopup = true);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _showStreakPopup = false);
      });
    }
  }

  Widget _buildStreakCard(BuildContext context) {
    final service = context.watch<StreakService>();
    final streak = service.count;
    if (streak <= 0) return const SizedBox.shrink();

    const threshold = StreakService.bonusThreshold;
    final highlight = service.hasBonus;
    final progressDays = streak >= threshold ? threshold : streak;
    final progress = progressDays / threshold;
    final accent = Theme.of(context).colorScheme.secondary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: responsiveSize(context, 24)),
          padding: responsiveAll(context, 12),
          decoration: BoxDecoration(
            color: highlight ? Colors.orange[700] : Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Стрик: $streak \u0434\u043D\u0435\u0439 \u043F\u043E\u0434\u0440\u044F\u0434',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                highlight ? Colors.white : accent),
                            minHeight: 6,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$progressDays/$threshold',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_showStreakPopup)
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: Offset(0, -20 * value),
                    child: child,
                  ),
                );
              },
              child: const Text(
                '+1🔥',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpotOfDaySection(BuildContext context) {
    final spot = _spotOfDay;
    if (spot == null) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: responsiveSize(context, 24)),
      padding: responsiveAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spot of the Day',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hero stack: ${spot.stacks[spot.heroIndex]}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Positions: ${spot.positions.join(', ')}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          TrainingSpotPreview(spot: spot),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrainingScreen(spot: spot)),
                );
              },
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(BuildContext context) {
    final goal = context.watch<GoalsService>().dailyGoal;
    if (goal == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final completed = goal.progress >= goal.target;
    final progress = (goal.progress / goal.target).clamp(0.0, 1.0);

    Widget buildActive() {
      return Column(
        key: const ValueKey('activeGoal'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Цель дня',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(goal.title),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text('${goal.progress}/${goal.target}')
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GoalsOverviewScreen()),
                );
              },
              child: const Text('Перейти'),
            ),
          ),
        ],
      );
    }

    Widget buildCompleted() {
      return Row(
        key: const ValueKey('completedGoal'),
        children: [
          const Icon(Icons.emoji_events, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Выполнено!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalsOverviewScreen()),
              );
            },
            child: const Text('Перейти'),
          ),
        ],
      );
    }

    final cardColor = completed ? Colors.green[700]! : Colors.grey[850]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: responsiveSize(context, 24)),
      padding: responsiveAll(context, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          final scale = Tween<double>(begin: 0.95, end: 1.0).animate(curved);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: completed ? buildCompleted() : buildActive(),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final goals = context.watch<GoalsService>();
    final executor = EvaluationExecutorService();
    final total = executor.summarizeHands(hands).totalHands;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = [
      for (final h in hands)
        if (h.date.isAfter(cutoff)) h
    ];
    final recentSummary = executor.summarizeHands(recent);
    final accuracy =
        recentSummary.totalHands > 0 ? recentSummary.accuracy : null;
    final completed = goals.goals.where((g) => g.completed).length;
    final streak = goals.errorFreeStreak;
    final show = total > 0 || accuracy != null || completed > 0 || streak > 0;
    if (!show) return const SizedBox.shrink();
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(text),
            ],
          ),
        );
    return Container(
      margin: EdgeInsets.only(bottom: responsiveSize(context, 24)),
      padding: responsiveAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.white),
              SizedBox(width: 8),
              Text('📈 Мой прогресс',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (total > 0) line(Icons.stacked_bar_chart, '$total раздач'),
          if (accuracy != null)
            line(Icons.check, 'Точность: ${accuracy.toStringAsFixed(0)}%'),
          if (completed > 0) line(Icons.flag, 'Целей достигнуто: $completed'),
          if (streak > 0) line(Icons.flash_on, 'Стрик: $streak рук'),
        ],
      ),
    );
  }

  Future<void> _toggleDemoMode(bool value) async {
    setState(() => _demoMode = value);
    await context.read<UserPreferencesService>().setDemoMode(value);
    if (value) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PokerAnalyzerDemoApp()),
      );
    }
  }

  Widget _buildSuggestedBanner(BuildContext context) {
    final service = context.watch<SuggestedPackService>();
    final tpl = service.template;
    final date = service.date;
    if (_dismissedDate != null &&
        DateTime.now().difference(_dismissedDate!).inDays >= 7 &&
        _suggestedDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _clearDismissed());
    }
    final show = !_suggestedDismissed &&
        tpl != null &&
        date != null &&
        DateTime.now().difference(date).inDays < 6;
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Dismissible(
        key: const ValueKey('suggestedBanner'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => _dismissSuggestedBanner(),
        child: Card(
          color: Colors.grey[850],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Новая подборка тренировок!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await context
                        .read<TrainingSessionService>()
                        .startSession(tpl!);
                    if (!context.mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TrainingSessionScreen()),
                    );
                  },
                  child: const Text('Начать тренировку'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_MenuItem> _buildMenuItems(BuildContext context) {
    return [
      _MenuItem(
        icon: Icons.sports_esports,
        label: 'Тренировка',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrainingPacksScreen()),
          );
        },
        key: _trainingButtonKey,
      ),
      _MenuItem(
        icon: Icons.add_circle,
        label: 'Новая раздача',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerInputScreen()),
          );
        },
        key: _newHandButtonKey,
      ),
      _MenuItem(
        icon: Icons.history,
        label: 'История',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllSessionsScreen()),
          );
        },
        key: _historyButtonKey,
      ),
      _MenuItem(
        icon: Icons.bar_chart,
        label: 'Аналитика',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgressScreen()),
          );
        },
      ),
      _MenuItem(
        icon: Icons.show_chart,
        label: 'Прогресс',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgressOverviewScreen()),
          );
        },
      ),
      _MenuItem(
        icon: Icons.timeline,
        label: 'История EV/ICM',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgressHistoryScreen()),
          );
        },
      ),
      _MenuItem(
        icon: Icons.calendar_today,
        label: 'Memory Insights',
        onTap: () {
          Navigator.pushNamed(context, MemoryInsightsScreen.route);
        },
      ),
      _MenuItem(
        icon: Icons.monitor_heart,
        label: 'Memory Health',
        onTap: () {
          Navigator.pushNamed(context, DecayDashboardScreen.route);
        },
      ),
      _MenuItem(
        icon: Icons.bar_chart,
        label: 'Decay Stats',
        onTap: () {
          Navigator.pushNamed(context, DecayStatsDashboardScreen.route);
        },
      ),
      _MenuItem(
        icon: Icons.grid_view,
        label: 'Decay Heatmap',
        onTap: () {
          Navigator.pushNamed(context, DecayHeatmapScreen.route);
        },
      ),
      _MenuItem(
        icon: Icons.tune,
        label: 'Decay Adaptation',
        onTap: () {
          Navigator.pushNamed(context, DecayAdaptationInsightScreen.route);
        },
      ),
      _MenuItem(
        icon: Icons.card_giftcard,
        label: 'Награды',
        onTap: () {
          Navigator.pushNamed(context, RewardGalleryScreen.route);
        },
      ),
      _MenuItem(
        icon: Icons.folder,
        label: 'Раздачи',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedHandsScreen()),
          );
        },
      ),
      _MenuItem(
        icon: Icons.settings,
        label: 'Настройки',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
    ];
  }

  Widget _buildMenuGrid(BuildContext context) {
    final items = _buildMenuItems(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final count = isLandscape(context) ? 3 : (compact ? 1 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              key: item.key,
              onTap: item.onTap,
              child: Card(
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 48, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text(item.label),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startTutorial() {
    final flow = TutorialFlow([
      TutorialStep(
        targetKey: _trainingButtonKey,
        description: 'Выберите тренировочный пак',
        onNext: (ctx, flow) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) => TrainingHomeScreen(tutorial: flow)),
          );
        },
      ),
      TutorialStep(
        targetKey: TrainingHomeScreen.recommendationsKey,
        description: 'Персональные дриллы. Запустите предложенный пак',
        onNext: (ctx, flow) {
          final nav = Navigator.of(ctx);
          nav.pop();
          flow.showCurrentStep(nav.context);
        },
      ),
      TutorialStep(
        targetKey: _newHandButtonKey,
        description: 'Затем решите раздачу',
        onNext: (_, __) {},
      ),
      TutorialStep(
        targetKey: _historyButtonKey,
        description: 'Просмотрите статистику ваших сессий',
        onNext: (ctx, flow) {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => TrainingHistoryScreen(tutorial: flow),
            ),
          );
        },
      ),
      TutorialStep(
        targetKey: TrainingHistoryScreen.exportCsvKey,
        description: 'Экспортируйте результаты для дальнейшего изучения',
        onNext: (_, __) {},
      ),
    ], onComplete: () {
      setState(() => _tutorialCompleted = true);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorialCompletionScreen(
            onRepeat: () {
              final nav = Navigator.of(context);
              nav.popUntil((route) => route.isFirst);
              flow.start(nav.context);
            },
          ),
        ),
      );
    });

    flow.start(context);
  }

  @override
  void dispose() {
    context.read<StreakService>().removeListener(_onStreakChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Poker AI Analyzer'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
          _buildStreakIndicator(context),
          if (!_tutorialCompleted)
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _startTutorial,
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LessonSuggestionBanner(),
                    const SmartDecayGoalBanner(),
                    const SmartMistakeGoalBanner(),
                    if (!_loadingSuggestions && _goalSuggestions.isNotEmpty)
                      GoalSuggestionRow(recommendations: _goalSuggestions),
                    const GoalReengagementBanner(),
                    const SmartRecapSuggestionBanner(),
                    const RecoveryPromptBanner(),
                    const RecapBannerWidget(),
                    _buildSuggestedBanner(context),
                    _buildStreakCard(context),
                    _buildDailyGoalCard(context),
                    const FocusOfTheWeekCard(),
                    _buildProgressCard(context),
                    _buildSpotOfDaySection(context),
                    const SkillTreeMainMenuEntry(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ReadyToTrainScreen()),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Тренироваться'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuGrid(context),
                    ListTile(
                      leading: const Icon(Icons.analytics, color: Colors.white),
                      trailing: const Icon(Icons.chevron_right),
                      title: const Text('Анализ ошибок'),
                      onTap: () {
                        Navigator.pushNamed(
                            context, WeaknessOverviewScreen.route);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _demoMode,
                      title: const Text('Demo Mode'),
                      onChanged: _toggleDemoMode,
                      activeColor: Colors.orange,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '🛠️ Инструменты',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final manager = Provider.of<SavedHandManagerService>(
                            context,
                            listen: false);
                        final service =
                            await HandHistoryFileService.create(manager);
                        await service.importFromFiles(context);
                      },
                      child: const Text('Импортировать Hand History'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SessionAnalysisImportScreen()),
                        );
                      },
                      child: const Text('Анализ сессии EV/ICM'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final exporter =
                            Provider.of<SavedHandExportService>(context,
                                listen: false);
                        final path = await exporter.exportAllHandsMarkdown();
                        if (!context.mounted) return;
                        SnackbarUtil.showMessage(context, path != null
                                ? 'Файл сохранён: all_saved_hands.md'
                                : 'Нет сохранённых раздач');
                      },
                      child: const Text('Экспорт всех раздач'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final exporter =
                            Provider.of<SavedHandExportService>(context,
                                listen: false);
                        final path = await exporter.exportAllHandsPdf();
                        if (!context.mounted) return;
                        SnackbarUtil.showMessage(context, path != null
                                ? 'Файл сохранён: all_saved_hands.pdf'
                                : 'Нет сохранённых раздач');
                      },
                      child: const Text('Экспорт PDF раздач'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GlobalEvaluationScreen()),
                        );
                      },
                      child: const Text('Глобальный пересчёт EV/ICM'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
