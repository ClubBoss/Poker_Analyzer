import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/personal_recommendation_service.dart';
import '../services/adaptive_training_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/training_session_service.dart';
import '../services/dynamic_pack_adjustment_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_template_detail_screen.dart';
import 'training_session_screen.dart';
import '../widgets/progress_forecast_card.dart';
import '../widgets/player_style_card.dart';

class TrainingRecommendationScreen extends StatefulWidget {
  const TrainingRecommendationScreen({super.key});

  @override
  State<TrainingRecommendationScreen> createState() => _TrainingRecommendationScreenState();
}

class _TrainingRecommendationScreenState extends State<TrainingRecommendationScreen> {
  final Map<String, TrainingPackStat?> _stats = {};
  final Map<String, double?> _delta = {};
  late PersonalRecommendationService _service;
  late VoidCallback _listener;
  bool _loading = true;
  List<TrainingPackTemplate> _tpls = [];
  List<RecommendationTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _service = context.read<PersonalRecommendationService>();
    _listener = () => unawaited(_update());
    _service.addListener(_listener);
    _refresh();
  }

  @override
  void dispose() {
    _service.removeListener(_listener);
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<AdaptiveTrainingService>().refresh();
  }

  Future<void> _update() async {
    final list = _service.packs.toList();
    final tasks = _service.tasks;
    final review = await MistakeReviewPackService.latestTemplate(context);
    if (review != null) list.insert(0, review);
    final adjust = context.read<DynamicPackAdjustmentService>();
    final stats = <String, TrainingPackStat?>{};
    final delta = <String, double?>{};
    final adjusted = <TrainingPackTemplate>[];
    for (final t in list) {
      stats[t.id] =
          context.read<AdaptiveTrainingService>().statFor(t.id) ??
              await TrainingPackStatsService.getStats(t.id);
      final hist = await TrainingPackStatsService.history(t.id);
      if (hist.length >= 2) {
        delta[t.id] =
            (hist.last.accuracy - hist[hist.length - 2].accuracy) * 100;
      }
      adjusted.add(await adjust.adjust(t));
    }
    if (!mounted) return;
    setState(() {
      _tpls = adjusted;
      _tasks = tasks;
      _stats
        ..clear()
        ..addAll(stats);
      _delta
        ..clear()
        ..addAll(delta);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рекомендации')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final tpl = await context
              .read<AdaptiveTrainingService>()
              .buildAdaptivePack();
          await context.read<TrainingSessionService>().startSession(tpl);
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
            );
          }
        },
        child: const Icon(Icons.auto_mode),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const ProgressForecastCard(),
                const PlayerStyleCard(),
                if (_tpls.isEmpty && _tasks.isEmpty)
                  const Center(child: Text('Нет рекомендаций'))
                else ...[
                  ..._tasks.map((t) => _TaskTile(task: t)),
                  ..._tpls.map((tpl) {
                    final stat = _stats[tpl.id];
                    final acc = (stat?.accuracy ?? 0) * 100;
                    final ev = stat?.postEvPct ?? 0;
                    final icm = stat?.postIcmPct ?? 0;
                    final rating = ((stat?.accuracy ?? 0) * 5).clamp(1, 5).round();
                    final focus = tpl.handTypeSummary();
                    final rangePct = ((tpl.heroRange?.length ?? 0) * 100 / 169).round();
                    final missCount =
                        context.read<MistakeReviewPackService>().mistakeCount(tpl.id);
                    final delta = _delta[tpl.id];
                    final diff = tpl.difficultyLevel;
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(tpl.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'LVL $diff • ${acc.toStringAsFixed(1)}% • EV ${ev.toStringAsFixed(1)}% • ICM ${icm.toStringAsFixed(1)}%'
                                ' • ${tpl.heroBbStack}bb • R $rangePct%'
                                '${missCount > 0 ? ' • $missCount ошиб.' : ''}${focus.isNotEmpty ? ' • $focus' : ''}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            if (delta != null) ...[
                              Icon(delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 14, color: delta >= 0 ? Colors.green : Colors.red),
                              const SizedBox(width: 2),
                              Text('${delta.abs().toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      color: delta >= 0 ? Colors.green : Colors.red,
                                      fontSize: 12)),
                            ]
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [for (var i = 0; i < rating; i++) const Icon(Icons.star, color: Colors.amber, size: 16)]),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.greenAccent),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrainingTemplateDetailScreen(
                                template: tpl,
                                stat: stat,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  })
                ]
              ],
            ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final RecommendationTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(task.icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
              child: Text(task.title,
                  style: const TextStyle(color: Colors.white))),
          Text('Еще ${task.remaining}',
              style: const TextStyle(color: Colors.white70))
        ],
      ),
    );
  }
}

