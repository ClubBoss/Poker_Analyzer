import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';

class TrainingProgressOverviewScreen extends StatelessWidget {
  static const route = '/training/progress';
  const TrainingProgressOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = context
        .watch<TrainingPackStorageService>()
        .packs
        .where((p) => !p.isBuiltIn)
        .toList()
      ..sort((a, b) => b.lastAttemptDate.compareTo(a.lastAttemptDate));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогресс по тренировкам'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: packs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = packs[index];
          final progress = p.pctComplete;
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
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Решено: ${p.solved}/${p.hands.length}'),
                    const Spacer(),
                    Text(DateFormat('dd.MM.yy').format(p.lastAttemptDate),
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}

