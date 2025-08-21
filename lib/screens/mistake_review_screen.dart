import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/mistake_insight.dart';
import '../models/mistake_tag_cluster.dart';
import '../models/training_pack_template.dart';
import '../services/mistake_tag_cluster_service.dart';
import '../services/mistake_tag_insights_service.dart';
import '../services/smart_review_service.dart';
import '../services/template_storage_service.dart';
import '../services/training_session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/v2/training_pack_spot_preview_card.dart';
import 'training_session_screen.dart';
import 'v2/training_pack_play_screen.dart';

class MistakeReviewScreen extends StatefulWidget {
  final TrainingPackTemplate? template;
  const MistakeReviewScreen({super.key, this.template});

  @override
  State<MistakeReviewScreen> createState() => _MistakeReviewScreenState();
}

class _MistakeReviewScreenState extends State<MistakeReviewScreen> {
  bool _loading = true;
  final Map<MistakeTagCluster, List<MistakeInsight>> _clusters = {};

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
    final insights = await const MistakeTagInsightsService(
      exampleCount: 2,
    ).buildInsights();
    const clusterSvc = MistakeTagClusterService();
    for (final ins in insights) {
      final c = clusterSvc.getClusterForTag(ins.tag);
      _clusters.putIfAbsent(c, () => []).add(ins);
    }
    setState(() => _loading = false);
  }

  Future<void> _startReview() async {
    final templates = context.read<TemplateStorageService>();
    final spots = await SmartReviewService.instance.getMistakeSpots(
      templates,
      context: context,
    );
    if (!mounted || spots.isEmpty) return;
    final tpl = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Повтор ошибок',
      createdAt: DateTime.now(),
      spots: spots,
    );
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  Widget _clusterCard(
    MistakeTagCluster cluster,
    List<MistakeInsight> insights,
  ) {
    final tags = insights.take(2).toList();
    final count = insights.fold<int>(0, (a, b) => a + b.count);
    final evLoss = insights.fold<double>(0, (a, b) => a + b.evLoss);
    final example =
        tags.first.examples.isNotEmpty ? tags.first.examples.first : null;
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cluster.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final t in tags)
              Text(
                '${t.tag.label}: ${t.shortExplanation}',
                style: const TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 8),
            Text(
              'Ошибок: $count',
              style: const TextStyle(color: Colors.white70),
            ),
            if (evLoss > 0)
              Text(
                'Потеря EV: ${evLoss.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70),
              ),
            if (example != null) ...[
              const SizedBox(height: 8),
              TrainingPackSpotPreviewCard(spot: example.spot),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _startReview,
                child: const Text('Повторить ошибки'),
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
        appBar: AppBar(title: const Text('Повтор ошибок')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Вы отлично справляетесь!',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startReview,
                child: const Text('Повторить прошлые ошибки'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Повтор ошибок')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in _clusters.entries) ...[
            _clusterCard(entry.key, entry.value),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
