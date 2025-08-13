import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_stats_service.dart';
import '../services/session_log_service.dart';

class PackInsightsBanner extends StatefulWidget {
  final String templateId;
  const PackInsightsBanner({super.key, required this.templateId});

  @override
  State<PackInsightsBanner> createState() => _PackInsightsBannerState();
}

class _PackInsightsBannerState extends State<PackInsightsBanner> {
  double? _accuracy;
  String? _topMistake;
  String _recommendation = '';
  int _sessions = 0;
  double? _avgTime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stat = await TrainingPackStatsService.getStats(widget.templateId);
    final completed =
        await TrainingPackStatsService.getHandsCompleted(widget.templateId);
    final logs = context.read<SessionLogService>().logs;
    final mistakes = <String, int>{};
    double timeSum = 0;
    int timeCount = 0;
    for (final l in logs) {
      if (l.templateId != widget.templateId) continue;
      for (final e in l.categories.entries) {
        mistakes.update(e.key, (v) => v + e.value, ifAbsent: () => e.value);
      }
      final hands = l.correctCount + l.mistakeCount;
      if (hands > 0) {
        timeSum += l.completedAt.difference(l.startedAt).inSeconds / hands;
        timeCount++;
      }
    }
    String? top;
    if (mistakes.isNotEmpty) {
      final entries = mistakes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      top = entries.first.key;
    }
    final mastered =
        await TrainingPackStatsService.isMastered(widget.templateId);
    final rec = mastered
        ? 'Освоено'
        : (stat != null && stat.accuracy >= 0.8
            ? 'Попробуйте похожее'
            : 'Повторить');
    if (mounted) {
      setState(() {
        _accuracy = stat?.accuracy;
        _topMistake = top;
        _recommendation = rec;
        _sessions = completed;
        _avgTime = timeCount > 0 ? timeSum / timeCount : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accuracy == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: accent),
              const SizedBox(width: 8),
              const Text('Pack Insights',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Средняя точность: ${(_accuracy! * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white)),
          if (_avgTime != null)
            Text('Среднее время ответа: ${_avgTime!.toStringAsFixed(1)} c',
                style: const TextStyle(color: Colors.white)),
          if (_topMistake != null)
            Text('Частая ошибка: $_topMistake',
                style: const TextStyle(color: Colors.white)),
          Text('Рекомендация: $_recommendation',
              style: const TextStyle(color: Colors.white)),
          Text('Сессий завершено: $_sessions',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
