import 'package:flutter/material.dart';

import 'player_input_screen.dart';
import 'saved_hands_screen.dart';
import 'training_packs_screen.dart';
import 'all_sessions_screen.dart';
import 'cloud_training_history_screen.dart';
import 'my_training_history_screen.dart';
import 'cloud_training_history_service_screen.dart';
import 'player_zone_demo_screen.dart';
import 'settings_screen.dart';
import 'daily_hand_screen.dart';
import 'spot_of_the_day_screen.dart';
import 'create_pack_screen.dart';
import 'edit_pack_screen.dart';
import 'template_library_screen.dart';
import 'my_training_packs_screen.dart';
import 'training_screen.dart';
import 'package:provider/provider.dart';
import '../services/hand_history_file_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_spot_of_day_service.dart';
import '../models/training_spot.dart';
import '../user_preferences.dart';
import '../main_demo.dart';
import '../widgets/training_spot_preview.dart';
import '../tutorial/tutorial_flow.dart';
import '../tutorial/tutorial_completion_screen.dart';
import 'training_history_screen.dart';
import 'session_stats_screen.dart';
import 'training_stats_screen.dart';
import 'progress_screen.dart';
import '../services/streak_service.dart';
import 'goals_overview_screen.dart';
import 'mistake_repeat_screen.dart';
import 'achievements_screen.dart';
import '../services/goals_service.dart';
import '../widgets/focus_of_the_week_card.dart';

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
    _demoMode = UserPreferences.instance.demoMode;
    _tutorialCompleted = UserPreferences.instance.tutorialCompleted;
    context.read<StreakService>().addListener(_onStreakChanged);
    _loadSpot();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StreakService>().updateStreak();
        context.read<GoalsService>().ensureDailyGoal();
      }
    });
  }

  Future<void> _loadSpot() async {
    final service = const TrainingSpotOfDayService();
    final spot = await service.getSpot();
    if (mounted) {
      setState(() => _spotOfDay = spot);
    }
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

    final threshold = StreakService.bonusThreshold;
    final highlight = service.hasBonus;
    final progressDays = streak >= threshold ? threshold : streak;
    final progress = progressDays / threshold;
    final accent = Theme.of(context).colorScheme.secondary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(12),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(highlight ? Colors.white : accent),
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
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
                  MaterialPageRoute(builder: (_) => const GoalsOverviewScreen()),
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
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
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
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
    final recent = [for (final h in hands) if (h.date.isAfter(cutoff)) h];
    final recentSummary = executor.summarizeHands(recent);
    final accuracy = recentSummary.totalHands > 0 ? recentSummary.accuracy : null;
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, color: Colors.white),
              SizedBox(width: 8),
              Text('📈 Мой прогресс',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (total > 0) line(Icons.stacked_bar_chart, '$total раздач'),
          if (accuracy != null)
            line(Icons.check, 'Точность: ${accuracy.toStringAsFixed(0)}%'),
          if (completed > 0)
            line(Icons.flag, 'Целей достигнуто: $completed'),
          if (streak > 0) line(Icons.flash_on, 'Стрик: $streak рук'),
        ],
      ),
    );
  }

  Future<void> _toggleDemoMode(bool value) async {
    setState(() => _demoMode = value);
    await UserPreferences.instance.setDemoMode(value);
    if (value) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PokerAnalyzerDemoApp()),
      );
    }
  }

  void _startTutorial() {
    final flow = TutorialFlow([
      TutorialStep(
        targetKey: _trainingButtonKey,
        description: 'Выберите тренировочный пак',
        onNext: (_, __) {},
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
          _buildStreakIndicator(context),
          if (!_tutorialCompleted)
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _startTutorial,
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStreakCard(context),
            _buildDailyGoalCard(context),
            const FocusOfTheWeekCard(),
            _buildProgressCard(context),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoalsOverviewScreen()),
                );
              },
              child: const Text('🎯 Мои цели'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                );
              },
              child: const Text('🏆 Достижения'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MistakeRepeatScreen()),
                );
              },
              child: const Text('🔁 Повторы ошибок'),
            ),
            const SizedBox(height: 16),
            _buildSpotOfDaySection(context),
            ElevatedButton(
              key: _newHandButtonKey,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerInputScreen()),
                );
              },
              child: const Text('➕ Новая раздача'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyHandScreen()),
                );
              },
              child: const Text('🃏 Ежедневная раздача'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpotOfTheDayScreen()),
                );
              },
              child: const Text('🎲 Спот дня'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedHandsScreen()),
                );
              },
              child: const Text('📂 Сохранённые раздачи'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: _trainingButtonKey,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingPacksScreen()),
                );
              },
              child: const Text('🎯 Тренировка'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreatePackScreen(),
                  ),
                );
              },
              child: const Text('📦 Создать тренировку'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditPackScreen(),
                  ),
                );
              },
              child: const Text('✏️ Редактировать тренировку'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TemplateLibraryScreen(),
                  ),
                );
              },
              child: const Text('📑 Шаблоны'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyTrainingPacksScreen()),
                );
              },
              child: const Text('🗂️ Мои паки'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: _historyButtonKey,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllSessionsScreen()),
                );
              },
              child: const Text('📈 История тренировок'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyTrainingHistoryScreen()),
                );
              },
              child: const Text('📒 Мои тренировки'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingHistoryScreen()),
                );
              },
              child: const Text('🗓️ Training History'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SessionStatsScreen()),
                );
              },
              child: const Text('📊 Статистика сессий'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingStatsScreen()),
                );
              },
              child: const Text('📈 Training Stats'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                );
              },
              child: const Text('📊 Прогресс'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CloudTrainingHistoryScreen()),
                );
              },
              child: const Text('☁️ Cloud History'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PlayerZoneDemoScreen()),
                );
              },
              child: const Text('🧪 Player Zone Demo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: const Text('⚙️ Settings'),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final manager =
                    Provider.of<SavedHandManagerService>(context, listen: false);
                final service = await HandHistoryFileService.create(manager);
                await service.importFromFiles(context);
              },
              child: const Text('Импортировать Hand History'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final manager =
                    Provider.of<SavedHandManagerService>(context, listen: false);
                final path = await manager.exportAllHandsMarkdown();
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
                final manager =
                    Provider.of<SavedHandManagerService>(context, listen: false);
                final path = await manager.exportAllHandsPdf();
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
          ],
        ),
      ),
    );
  }
}
