import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/responsive.dart';
import 'global_evaluation_screen.dart';
import 'package:provider/provider.dart';
import '../services/hand_history_file_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/saved_hand_export_service.dart';
import '../services/training_spot_of_day_service.dart';
import '../models/training_spot.dart';
import '../services/user_preferences_service.dart';
import '../main_demo.dart';
import '../tutorial/tutorial_flow.dart';
import '../tutorial/tutorial_completion_screen.dart';
import 'onboarding_screen.dart';
import 'training_history_screen.dart';
import 'session_stats_screen.dart';
import 'training_stats_screen.dart';
import '../services/streak_service.dart';
import 'achievements_screen.dart';
import '../services/goals_service.dart';
import '../widgets/focus_of_the_week_card.dart';
import '../widgets/sync_status_widget.dart';
import 'weakness_overview_screen.dart';
import 'training_home_screen.dart';
import 'ready_to_train_screen.dart';
import '../ui/history/history_screen.dart';
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
import '../widgets/main_menu/main_menu_streak_card.dart';
import '../widgets/main_menu/main_menu_spot_of_day_section.dart';
import '../widgets/main_menu/main_menu_daily_goal_card.dart';
import '../widgets/main_menu/main_menu_progress_card.dart';
import '../widgets/main_menu/main_menu_suggested_banner.dart';
import '../widgets/main_menu/main_menu_grid.dart';

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
                    MainMenuSuggestedBanner(
                      suggestedDismissed: _suggestedDismissed,
                      dismissedDate: _dismissedDate,
                      onDismissed: _dismissSuggestedBanner,
                      onClearDismissed: _clearDismissed,
                    ),
                    MainMenuStreakCard(showPopup: _showStreakPopup),
                    const MainMenuDailyGoalCard(),
                    const FocusOfTheWeekCard(),
                    const MainMenuProgressCard(),
                    if (_spotOfDay != null)
                      MainMenuSpotOfDaySection(spot: _spotOfDay!),
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
                    MainMenuGrid(
                      trainingButtonKey: _trainingButtonKey,
                      newHandButtonKey: _newHandButtonKey,
                      historyButtonKey: _historyButtonKey,
                    ),
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.white),
                      trailing: const Icon(Icons.chevron_right),
                      title: const Text('History'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoryScreen()),
                        );
                      },
                    ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(path != null
                                ? 'Файл сохранён: all_saved_hands.md'
                                : 'Нет сохранённых раздач'),
                          ),
                        );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(path != null
                                ? 'Файл сохранён: all_saved_hands.pdf'
                                : 'Нет сохранённых раздач'),
                          ),
                        );
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
