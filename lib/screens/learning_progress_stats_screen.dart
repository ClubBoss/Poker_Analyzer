import 'package:flutter/material.dart';

import '../services/learning_path_progress_service.dart';

class LearningProgressStatsScreen extends StatelessWidget {
  const LearningProgressStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LearningStageState>>(
      future: LearningPathProgressService.instance.getCurrentStageState(),
      builder: (context, snapshot) {
        final stages = snapshot.data ?? [];
        return Scaffold(
          appBar: AppBar(
              title: const Text('\uD83D\uDCCA Статистика')), // '📊 Статистика'
          backgroundColor: const Color(0xFF121212),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    return _StageStatsTile(stage: stage);
                  },
                ),
        );
      },
    );
  }
}

class _StageStatsTile extends StatelessWidget {
  final LearningStageState stage;
  const _StageStatsTile({required this.stage});

  Color _color(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress > 0.0) return Colors.yellow;
    return Colors.grey;
  }

  IconData _icon(int index) {
    switch (index) {
      case 1:
        return Icons.filter_1;
      case 2:
        return Icons.filter_2;
      case 3:
        return Icons.filter_3;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = computeStageProgress(stage.items);
    final done = stage.items
        .where((e) => e.status == LearningItemStatus.completed)
        .length;
    final color = _color(progress);
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(_icon(stage.levelIndex), color: color),
        trailing: progress >= 1.0
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        title: Text(stage.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$done / ${stage.items.length} паков'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}

double computeStageProgress(List<LearningStageItem> items) {
  if (items.isEmpty) return 0.0;
  var sum = 0.0;
  for (final item in items) {
    switch (item.status) {
      case LearningItemStatus.completed:
        sum += 1.0;
        break;
      case LearningItemStatus.available:
        sum += 0.5;
        break;
      case LearningItemStatus.inProgress:
        sum += 0.75;
        break;
      case LearningItemStatus.locked:
      default:
        break;
    }
  }
  return sum / items.length;
}
