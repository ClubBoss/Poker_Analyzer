import 'package:flutter/material.dart';

import 'analyzer_tab.dart';
import 'spot_of_the_day_screen.dart';
import 'spot_of_the_day_history_screen.dart';
import 'settings_placeholder_screen.dart';
import '../widgets/streak_banner.dart';
import '../widgets/motivation_card.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Widget _home() {
    return const Column(
      children: [
        MotivationCard(),
        Expanded(child: AnalyzerTab()),
      ],
    );
  }

  void _onTap(int index) {
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
