import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/reward_system_service.dart';
import '../services/streak_counter_service.dart';
import '../services/training_pack_stats_service.dart';

class PlayerStatsScreen extends StatefulWidget {
  static const route = '/player_stats';
  const PlayerStatsScreen({super.key});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  GlobalPackStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await TrainingPackStatsService.getGlobalStats();
    if (mounted) setState(() => _stats = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\uD83D\uDCC8 Моя статистика'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Consumer<RewardSystemService>(
            builder: (context, rewards, _) => ListTile(
              leading: const Text(
                '\uD83E\uDDE0',
                style: TextStyle(fontSize: 20),
              ),
              title: Text('Уровень: ${rewards.currentLevel}'),
              subtitle: LinearProgressIndicator(value: rewards.progress),
              trailing: Text(
                '${rewards.xpProgress} / ${rewards.xpToNextLevel} XP',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<StreakCounterService>(
            builder: (context, streak, _) => ListTile(
              leading: const Text(
                '\uD83D\uDD25',
                style: TextStyle(fontSize: 20),
              ),
              title: const Text('Максимальный стрик'),
              trailing: Text('${streak.max}'),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Text('\uD83C\uDFAF', style: TextStyle(fontSize: 20)),
            title: const Text('Средняя точность'),
            trailing: Text(
              _stats != null
                  ? '${(_stats!.averageAccuracy * 100).round()}%'
                  : '...',
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Text('\u2705', style: TextStyle(fontSize: 20)),
            title: const Text('Завершено паков'),
            trailing: Text(
              _stats != null ? '${_stats!.packsCompleted}' : '...',
            ),
          ),
        ],
      ),
    );
  }
}
