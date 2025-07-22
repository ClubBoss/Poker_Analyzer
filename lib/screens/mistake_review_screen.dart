import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/mistake_tag_cluster_service.dart';
import '../services/mistake_tag_history_service.dart';
import '../services/mistake_tag_insights_service.dart';
import '../services/template_storage_service.dart';
import 'v2/training_pack_play_screen.dart';

class MistakeReviewScreen extends StatefulWidget {
  final TrainingPackTemplate? template;
  const MistakeReviewScreen({super.key, this.template});

  @override
  State<MistakeReviewScreen> createState() => _MistakeReviewScreenState();
}

class _ClusterVM {
  final MistakeTagCluster cluster;
  final List<MistakeTagInsight> tags;
  final int count;
  final double evLoss;
  final TrainingPackSpot? example;
  const _ClusterVM({
    required this.cluster,
    required this.tags,
    required this.count,
    required this.evLoss,
    this.example,
  });
}

class _MistakeReviewScreenState extends State<MistakeReviewScreen> {
  bool _loading = true;
  final List<_ClusterVM> _clusters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.template != null) {
      setState(() => _loading = false);
      return;
    }
    final insights = await const MistakeTagInsightsService().computeInsights();
    final templates = context.read<TemplateStorageService>().templates;
    final spotMap = <String, Map<String, TrainingPackSpot>>{};
    for (final t in templates) {
      spotMap[t.id] = {for (final s in t.spots) s.id: s};
    }
    final clusters = <_ClusterVM>[];
    for (final c in insights) {
      TrainingPackSpot? spot;
      for (final t in c.tagInsights) {
        final hist = await MistakeTagHistoryService.getRecentMistakesByTag(t.tag, limit: 1);
        if (hist.isNotEmpty) {
          spot = spotMap[hist.first.packId]?[hist.first.spotId];
          if (spot != null) break;
        }
      }
      clusters.add(_ClusterVM(
        cluster: c.cluster,
        tags: c.tagInsights,
        count: c.totalCount,
        evLoss: c.totalEvLoss,
        example: spot,
      ));
    }
    setState(() {
      _clusters
        ..clear()
        ..addAll(clusters);
      _loading = false;
    });
  }

  Future<void> _startReview() async {
    final tpl = await MistakeReviewPackService.latestTemplate(context);
    if (tpl == null) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MistakeReviewScreen(template: tpl)),
    );
  }

  Widget _clusterTile(_ClusterVM c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.cluster.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Mistakes: ${c.count} · EV loss: ${c.evLoss.toStringAsFixed(2)}'),
            if (c.tags.isNotEmpty)
              Text('Top tags: ${c.tags.map((e) => e.tag.label).take(2).join(', ')}'),
            if (c.example != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Example: ${c.example!.title}'),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _startReview,
                child: const Text('Review mistakes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tpl = widget.template;
    if (tpl != null) {
      return TrainingPackPlayScreen(template: tpl, original: tpl);
    }
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_clusters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mistake Review')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("You're doing great!"),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _startReview,
                child: const Text('Review past mistakes'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mistake Review')),
      body: ListView(
        children: [for (final c in _clusters) _clusterTile(c)],
      ),
    );
  }
}
