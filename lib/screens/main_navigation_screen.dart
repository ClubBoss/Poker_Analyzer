import 'package:flutter/material.dart';

import 'analyzer_tab.dart';
import 'spot_of_the_day_screen.dart';
import 'spot_of_the_day_history_screen.dart';
import 'settings_placeholder_screen.dart';
import 'insights_screen.dart';
import 'goal_overview_screen.dart';
import '../widgets/streak_banner.dart';
import '../widgets/motivation_card.dart';
import '../widgets/next_step_card.dart';
import '../widgets/suggested_drill_card.dart';
import '../widgets/today_progress_banner.dart';
import '../widgets/streak_mini_card.dart';
import '../widgets/streak_chart.dart';
import '../widgets/spot_of_the_day_card.dart';
import 'streak_history_screen.dart';
import '../services/user_action_logger.dart';
import '../services/daily_target_service.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Future<void> _setDailyGoal() async {
    final service = context.read<DailyTargetService>();
    final controller = TextEditingController(text: service.target.toString());
    final int? value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Daily Goal', style: TextStyle(color: Colors.white)),
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

  Widget _home() {
    return Column(
      children: [
        const SpotOfTheDayCard(),
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
        const NextStepCard(),
        const SuggestedDrillCard(),
        const Expanded(child: AnalyzerTab()),
      ],
    );
  }

  void _onTap(int index) {
    UserActionLogger.instance.log('nav_$index');
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      const SpotOfTheDayScreen(),
      const SpotOfTheDayHistoryScreen(),
      const GoalOverviewScreen(),
      const InsightsScreen(),
      const SettingsPlaceholderScreen(),
    ];
    return Scaffold(
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
            items: const [
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
                icon: Icon(Icons.flag),
                label: 'Goal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights),
                label: '📊 Insights',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz),
                label: 'Ещё',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
