import 'dart:async';

import 'package:flutter/material.dart';

import '../services/decay_spot_booster_engine.dart';
import '../services/theory_tag_decay_tracker.dart';
import '../services/theory_booster_queue_service.dart';

/// Dashboard tile showing most decayed theory tags with quick actions.
class SkillDecayDashboardTile extends StatefulWidget {
  const SkillDecayDashboardTile({super.key});

  @override
  State<SkillDecayDashboardTile> createState() =>
      _SkillDecayDashboardTileState();
}

class _SkillDecayDashboardTileState extends State<SkillDecayDashboardTile> {
  late Future<List<MapEntry<String, double>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MapEntry<String, double>>> _load() async {
    final tracker = TheoryTagDecayTracker();
    final scores = await tracker.computeDecayScores();
    final entries = scores.entries.where((e) => e.value > 50).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }

  Future<void> _trainSpots(String tag) async {
    final engine = DecaySpotBoosterEngine();
    await engine.enqueueForTag(tag);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Споты добавлены в очередь')));
  }

  Future<void> _reviewTheory(String tag) async {
    await TheoryBoosterQueueService.instance.enqueue(tag);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Теория добавлена в очередь')));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<List<MapEntry<String, double>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📉 Skill Decay',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (final e in list)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${e.key} • ${e.value.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _trainSpots(e.key),
                        child: const Text('Тренировать споты'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => _reviewTheory(e.key),
                        child: const Text('Повторить теорию'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
