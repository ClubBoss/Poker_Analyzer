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
      const _MenuItem(
        icon: Icons.sports_esports,
        label: 'Тренировка',
        onTap: _onTrainingTap,
      ),
      const _MenuItem(
        icon: Icons.add_circle,
        label: 'Новая раздача',
        onTap: _onNewHandTap,
      ),
      const _MenuItem(
        icon: Icons.history,
        label: 'История',
        onTap: _onHistoryTap,
      ),
      const _MenuItem(
        icon: Icons.bar_chart,
        label: 'Аналитика',
        onTap: _onAnalyticsTap,
      ),
      const _MenuItem(
        icon: Icons.show_chart,
        label: 'Прогресс',
        onTap: _onProgressTap,
      ),
      const _MenuItem(
        icon: Icons.timeline,
        label: 'История EV/ICM',
        onTap: _onProgressHistoryTap,
      ),
      const _MenuItem(
        icon: Icons.calendar_today,
        label: 'Memory Insights',
        onTap: _onMemoryInsightsTap,
      ),
      const _MenuItem(
        icon: Icons.monitor_heart,
        label: 'Memory Health',
        onTap: _onMemoryHealthTap,
      ),
      const _MenuItem(
        icon: Icons.bar_chart,
        label: 'Decay Stats',
        onTap: _onDecayStatsTap,
      ),
      const _MenuItem(
        icon: Icons.grid_view,
        label: 'Decay Heatmap',
        onTap: _onDecayHeatmapTap,
      ),
      const _MenuItem(
        icon: Icons.tune,
        label: 'Decay Adaptation',
        onTap: _onDecayAdaptationTap,
      ),
      const _MenuItem(
        icon: Icons.card_giftcard,
        label: 'Награды',
        onTap: _onRewardGalleryTap,
      ),
      const _MenuItem(
        icon: Icons.folder,
        label: 'Раздачи',
        onTap: _onSavedHandsTap,
      ),
      const _MenuItem(
        icon: Icons.settings,
        label: 'Настройки',
        onTap: _onSettingsTap,
      ),
    ];
  }

  static void _onTrainingTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingPacksScreen()),
    );
  }

  static void _onNewHandTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerInputScreen()),
    );
  }

  static void _onHistoryTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllSessionsScreen()),
    );
  }

  static void _onAnalyticsTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgressScreen()),
    );
  }

  static void _onProgressTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgressOverviewScreen()),
    );
  }

  static void _onProgressHistoryTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgressHistoryScreen()),
    );
  }

  static void _onMemoryInsightsTap(BuildContext context) {
    Navigator.pushNamed(context, MemoryInsightsScreen.route);
  }

  static void _onMemoryHealthTap(BuildContext context) {
    Navigator.pushNamed(context, DecayDashboardScreen.route);
  }

  static void _onDecayStatsTap(BuildContext context) {
    Navigator.pushNamed(context, DecayStatsDashboardScreen.route);
  }

  static void _onDecayHeatmapTap(BuildContext context) {
    Navigator.pushNamed(context, DecayHeatmapScreen.route);
  }

  static void _onDecayAdaptationTap(BuildContext context) {
    Navigator.pushNamed(context, DecayAdaptationInsightScreen.route);
  }

  static void _onRewardGalleryTap(BuildContext context) {
    Navigator.pushNamed(context, RewardGalleryScreen.route);
  }

  static void _onSavedHandsTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedHandsScreen()),
    );
  }

  static void _onSettingsTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
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
              key: index == 0
                  ? trainingButtonKey
                  : index == 1
                      ? newHandButtonKey
                      : index == 2
                          ? historyButtonKey
                          : null,
              onTap: () => item.onTap(context),
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
  final void Function(BuildContext context) onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

