import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adaptive_training_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/training_session_service.dart';
import '../services/dynamic_pack_adjustment_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_template_detail_screen.dart';
import 'training_session_screen.dart';

class TrainingRecommendationScreen extends StatefulWidget {
  const TrainingRecommendationScreen({super.key});

  @override
  State<TrainingRecommendationScreen> createState() => _TrainingRecommendationScreenState();
}

class _TrainingRecommendationScreenState extends State<TrainingRecommendationScreen> {
  final Map<String, TrainingPackStat?> _stats = {};
  final Map<String, double?> _delta = {};
  late AdaptiveTrainingService _service;
  bool _loading = true;
  List<TrainingPackTemplate> _tpls = [];

  @override
  void initState() {
    super.initState();
    _service = context.read<AdaptiveTrainingService>();
    _service.recommendedNotifier.addListener(_update);
    _refresh();
  }

  @override
  void dispose() {
    _service.recommendedNotifier.removeListener(_update);
    super.dispose();
  }

  Future<void> _refresh() async {
    await _service.refresh();
  }

  Future<void> _update() async {
    final list = _service.recommendedNotifier.value.toList();
    final review = await MistakeReviewPackService.latestTemplate(context);
    if (review != null) list.insert(0, review);
    final adjust = context.read<DynamicPackAdjustmentService>();
    final stats = <String, TrainingPackStat?>{};
    final delta = <String, double?>{};
    final adjusted = <TrainingPackTemplate>[];
    for (final t in list) {
      stats[t.id] =
          _service.statFor(t.id) ?? await TrainingPackStatsService.getStats(t.id);
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
          final tpl = await _service.buildAdaptivePack();
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
          : _tpls.isEmpty
              ? const Center(child: Text('Нет рекомендаций'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tpls.length,
                  itemBuilder: (context, index) {
                    final tpl = _tpls[index];
                    final stat = _stats[tpl.id];
                    final acc = (stat?.accuracy ?? 0) * 100;
                    final ev = stat?.postEvPct ?? 0;
                    final icm = stat?.postIcmPct ?? 0;
                    final rating = ((stat?.accuracy ?? 0) * 5).clamp(1, 5).round();
                    final focus = tpl.handTypeSummary();
                    final rangePct =
                        ((tpl.heroRange?.length ?? 0) * 100 / 169).round();
                    final hasMistakes = context.read<MistakeReviewPackService>().hasMistakes(tpl.id);
                    final diff = tpl.difficultyLevel;
                    final missCount = context.read<MistakeReviewPackService>().mistakeCount(tpl.id);
                    final delta = _delta[tpl.id];
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
                  },
                ),
    );
  }
}
