import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adaptive_training_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/training_pack_stats_service.dart';
import '../models/v2/training_pack_template.dart';
import 'training_template_detail_screen.dart';

class TrainingRecommendationScreen extends StatefulWidget {
  const TrainingRecommendationScreen({super.key});

  @override
  State<TrainingRecommendationScreen> createState() => _TrainingRecommendationScreenState();
}

class _TrainingRecommendationScreenState extends State<TrainingRecommendationScreen> {
  final Map<String, TrainingPackStat?> _stats = {};
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
    final stats = <String, TrainingPackStat?>{};
    for (final t in list) {
      stats[t.id] = _service.statFor(t.id) ?? await TrainingPackStatsService.getStats(t.id);
    }
    if (!mounted) return;
    setState(() {
      _tpls = list;
      _stats
        ..clear()
        ..addAll(stats);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рекомендации')),
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
                    final hasMistakes = context.read<MistakeReviewPackService>().hasMistakes(tpl.id);
                    final diff = tpl.difficultyLevel;
                    final missCount = context.read<MistakeReviewPackService>().mistakeCount(tpl.id);
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(tpl.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'LVL $diff • ${acc.toStringAsFixed(1)}% • EV ${ev.toStringAsFixed(1)}% • ICM ${icm.toStringAsFixed(1)}%'
                          '${missCount > 0 ? ' • $missCount ошиб.' : ''}${focus.isNotEmpty ? ' • $focus' : ''}',
                          style: const TextStyle(color: Colors.white70),
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
