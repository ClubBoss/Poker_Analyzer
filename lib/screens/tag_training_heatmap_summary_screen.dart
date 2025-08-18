import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_mastery_history_service.dart';
import '../widgets/training_heatmap.dart';
import '../widgets/sync_status_widget.dart';

class TagTrainingHeatmapSummaryScreen extends StatefulWidget {
  static const route = '/training/heatmap_summary';
  const TagTrainingHeatmapSummaryScreen({super.key});

  @override
  State<TagTrainingHeatmapSummaryScreen> createState() =>
      _TagTrainingHeatmapSummaryScreenState();
}

class _TagTrainingHeatmapSummaryScreenState
    extends State<TagTrainingHeatmapSummaryScreen> {
  bool _loading = true;
  Map<DateTime, int> _data = {};
  bool _xpOnly = false;
  int _streak = 0;
  double _avgXp = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = context.read<TagMasteryHistoryService>();
    final hist = await service.getHistory();
    final map = <DateTime, int>{};
    for (final list in hist.values) {
      for (final e in list) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        map[d] = (map[d] ?? 0) + e.xp;
      }
    }
    const days = 90;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: days - 1));
    final values = <int>[];
    for (int i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      values.add(map[date] ?? 0);
    }
    int streak = 0;
    for (int i = values.length - 1; i >= 0; i--) {
      if (values[i] > 0) {
        streak++;
      } else {
        break;
      }
    }
    final total = values.fold<int>(0, (p, e) => p + e);
    final avg = days > 0 ? total / days : 0.0;
    setState(() {
      _data = map;
      _streak = streak;
      _avgXp = avg;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Heatmap'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '🎯 Твоя активность по дням',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TrainingHeatmap(dailyXp: _data, xpOnly: _xpOnly),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Стрик: $_streak',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Среднее XP: ${_avgXp.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                SwitchListTile(
                  value: _xpOnly,
                  onChanged: (v) => setState(() => _xpOnly = v),
                  title: const Text(
                    'Только активные дни',
                    style: TextStyle(color: Colors.white),
                  ),
                  activeThumbColor: Colors.greenAccent,
                ),
              ],
            ),
    );
  }
}
