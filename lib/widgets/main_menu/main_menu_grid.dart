import 'package:flutter/material.dart';

import '../../screens/player_input_screen.dart';
import '../../screens/saved_hands_screen.dart';
import '../../screens/training_packs_screen.dart';
import '../../screens/all_sessions_screen.dart';
import '../../screens/progress_screen.dart';
import '../../screens/progress_overview_screen.dart';
import '../../screens/progress_history_screen.dart';
import '../../screens/memory_insights_screen.dart';
import '../../screens/decay_dashboard_screen.dart';
import '../../screens/decay_stats_dashboard_screen.dart';
import '../../screens/decay_heatmap_screen.dart';
import '../../screens/decay_adaptation_insight_screen.dart';
import '../../screens/reward_gallery_screen.dart';
import '../../screens/settings_screen.dart';
import '../../utils/responsive.dart';

class MainMenuGrid extends StatelessWidget {
  final Key trainingButtonKey;
  final Key newHandButtonKey;
  final Key historyButtonKey;

  const MainMenuGrid({
    super.key,
    required this.trainingButtonKey,
    required this.newHandButtonKey,
    required this.historyButtonKey,
  });

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
        key: trainingButtonKey,
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
        key: newHandButtonKey,
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
        key: historyButtonKey,
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

  @override
  Widget build(BuildContext context) {
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
}

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

