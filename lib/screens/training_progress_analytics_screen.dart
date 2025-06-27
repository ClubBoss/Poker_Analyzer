import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';

class TrainingProgressAnalyticsScreen extends StatelessWidget {
  static const route = '/training/analytics';
  const TrainingProgressAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = context
        .watch<TrainingPackStorageService>()
        .packs
        .where((p) => !p.isBuiltIn)
        .toList();
    final Map<String, _CategoryStats> map = {};
    for (final p in packs) {
      final c = p.category.isNotEmpty ? p.category : 'Без категории';
      map.putIfAbsent(c, () => _CategoryStats()).add(p);
    }
    final stats = map.entries
        .where((e) => e.value.attempts > 0)
        .toList()
      ..sort((a, b) => b.value.attempts.compareTo(a.value.attempts));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика по категориям'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final e = stats[index];
          final s = e.value;
          final progress = s.avgProgress;
          final color = progress < 0.5
              ? Colors.redAccent
              : progress < 0.8
                  ? Colors.orangeAccent
                  : Colors.greenAccent;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Попыток: ${s.attempts} • Решено: ${s.solved}'),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Средний прогресс: ${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryStats {
  int packs = 0;
  int attempts = 0;
  int solved = 0;
  double progress = 0.0;

  void add(TrainingPack p) {
    packs += 1;
    attempts += p.lastAttempted;
    solved += p.solved;
    progress += p.pctComplete;
  }

  double get avgProgress => packs == 0 ? 0 : progress / packs;
}
