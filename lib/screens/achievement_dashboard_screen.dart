import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/achievement_service.dart';
import '../models/achievement_info.dart';
import '../widgets/achievement_tile.dart';
import '../widgets/xp_progress_card.dart';

class AchievementDashboardScreen extends StatefulWidget {
  const AchievementDashboardScreen({super.key});

  @override
  State<AchievementDashboardScreen> createState() =>
      _AchievementDashboardScreenState();
}

class _AchievementDashboardScreenState
    extends State<AchievementDashboardScreen> {
  bool _unlockedOnly = false;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AchievementService>();
    final data = service.allAchievements();
    final Map<String, List<AchievementInfo>> grouped = {};
    for (final a in data) {
      if (_unlockedOnly && !a.completed) continue;
      grouped.putIfAbsent(a.category, () => []).add(a);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_unlockedOnly ? Icons.lock_open : Icons.lock_outline),
            tooltip: _unlockedOnly ? 'Все' : 'Показать только разблокированные',
            onPressed: () => setState(() => _unlockedOnly = !_unlockedOnly),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const XPProgressCard(),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final count = compact ? 1 : 2;
                return GridView.builder(
                  itemCount: entry.value.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final ach = entry.value[index];
                    final tag = '${ach.id}_hero';
                    return AchievementTile(
                      achievement: ach,
                      heroTag: tag,
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
