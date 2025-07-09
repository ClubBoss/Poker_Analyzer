import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';
import 'training_activity_by_weekday_screen.dart';
import 'top_mistakes_overview_screen.dart';
import '../widgets/sync_status_widget.dart';
import '../helpers/category_translations.dart';

class TrainingProgressAnalyticsScreen extends StatefulWidget {
  static const route = '/training/analytics';
  const TrainingProgressAnalyticsScreen({super.key});

  @override
  State<TrainingProgressAnalyticsScreen> createState() => _TrainingProgressAnalyticsScreenState();
}

class _TrainingProgressAnalyticsScreenState extends State<TrainingProgressAnalyticsScreen> {
  String _selected = 'Все категории';

  @override
  Widget build(BuildContext context) {
    final packs = context
        .watch<TrainingPackStorageService>()
        .packs
        .where((p) => !p.isBuiltIn)
        .toList();
    final Map<String, _CategoryStats> map = {};
    for (final p in packs) {
      final raw = p.category.isNotEmpty ? p.category : 'Без категории';
      final c = translateCategory(raw);
      map.putIfAbsent(c, () => _CategoryStats()).add(p);
    }
    const priority = {
      'Пуш/Фолд': 1,
      'ICM': 2,
      'Постфлоп': 3,
      '3-бет': 4,
    };
    final stats = map.entries
        .where((e) => e.value.attempts > 0)
        .toList()
      ..sort((a, b) {
        final pa = priority[a.key];
        final pb = priority[b.key];
        if (pa != null && pb != null) return pa.compareTo(pb);
        if (pa != null) return -1;
        if (pb != null) return 1;
        return a.key.compareTo(b.key);
      });
    final categories = ['Все категории', ...stats.map((e) => e.key)];
    final filtered = _selected == 'Все категории'
        ? stats
        : stats.where((e) => e.key == _selected).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика по категориям'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context), 
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TrainingActivityByWeekdayScreen()),
              );
            },
            child: const Text(
              'Дни недели',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TopMistakesOverviewScreen()),
              );
            },
            child: const Text(
              'Ошибки',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: _selected,
              dropdownColor: AppColors.cardBackground,
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: Colors.white),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c, child: Text(c))
              ],
              onChanged: (v) => setState(() => _selected = v ?? 'Все категории'),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = filtered[index];
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
                      Text(e.key,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      Text(
                          'Средний прогресс: ${(progress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
