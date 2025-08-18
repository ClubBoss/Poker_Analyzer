import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_stats.dart';
import '../services/template_storage_service.dart';
import '../services/training_stats_service.dart';
import '../services/streak_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../widgets/ev_icm_trend_chart.dart';
import '../widgets/streak_history_calendar.dart';

class TrainingStatsScreen extends StatefulWidget {
  const TrainingStatsScreen({super.key});

  @override
  State<TrainingStatsScreen> createState() => _TrainingStatsScreenState();
}

class _TrainingStatsScreenState extends State<TrainingStatsScreen> {
  TrainingStats? _stats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final service = context.read<TrainingStatsService>();
    final templates = context.read<TemplateStorageService>();
    final streak = context.read<StreakService>();
    final stats = await service.aggregate(templates: templates, streak: streak);
    if (mounted) setState(() => _stats = stats);
  }

  Widget _buildPackTile(PackAccuracy p) {
    return ListTile(
      title: Text(p.name),
      trailing: Text('${(p.accuracy * 100).round()}%'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_stats == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Stats'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () =>
                  context.read<TrainingStatsService>().shareProgress(),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final s = _stats!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () =>
                context.read<TrainingStatsService>().shareProgress(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Spots: ${s.totalSpots}'),
                  const SizedBox(height: 4),
                  Text(
                    'Average Accuracy: ${(s.avgAccuracy * 100).toStringAsFixed(1)}%',
                  ),
                  const SizedBox(height: 4),
                  Text('Streak: ${s.streakDays} days'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          EvIcmTrendChart(
            sessionDates: context.watch<TrainingStatsService>().sessionHistory(
              context.watch<SavedHandManagerService>().hands,
            ),
          ),
          const SizedBox(height: 16),
          const StreakHistoryCalendar(),
          if (s.topPacks.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Best Packs'),
            const SizedBox(height: 8),
            for (final p in s.topPacks) _buildPackTile(p),
          ],
          if (s.bottomPacks.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Worst Packs'),
            const SizedBox(height: 8),
            for (final p in s.bottomPacks) _buildPackTile(p),
          ],
        ],
      ),
    );
  }
}
