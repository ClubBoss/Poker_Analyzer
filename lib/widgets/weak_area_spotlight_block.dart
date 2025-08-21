import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mistake_tag_cluster.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../services/booster_suggestion_engine.dart';
import '../services/mistake_tag_cluster_service.dart';
import '../services/mistake_tag_insights_service.dart';
import '../services/training_pack_stats_service_v2.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class WeakAreaSpotlightBlock extends StatefulWidget {
  const WeakAreaSpotlightBlock({super.key});

  @override
  State<WeakAreaSpotlightBlock> createState() => _WeakAreaSpotlightBlockState();
}

class _WeakAreaSpotlightBlockState extends State<WeakAreaSpotlightBlock> {
  bool _loading = true;
  MistakeTagCluster? _cluster;
  double _evLoss = 0.0;
  TrainingPackTemplateV2? _pack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final improvement = await TrainingPackStatsServiceV2.improvementByTag();
    if (improvement.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // Determine weakest cluster by improvement
    MistakeTagCluster? cluster;
    for (final e in (improvement.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)))) {
      final c = MistakeTagCluster.values.firstWhere(
        (cl) => cl.label.toLowerCase() == e.key.toLowerCase(),
        orElse: () => MistakeTagCluster.aggressiveMistakes,
      );
      cluster = c;
      break;
    }
    if (cluster == null) {
      setState(() => _loading = false);
      return;
    }

    final insights = await const MistakeTagInsightsService().buildInsights(
      sortByEvLoss: true,
    );
    const clusterService = MistakeTagClusterService();
    double loss = 0.0;
    for (final i in insights) {
      if (clusterService.getClusterForTag(i.tag) == cluster) {
        loss += i.evLoss;
      }
    }

    final boosterId = await const BoosterSuggestionEngine().suggestBooster(
      improvement: improvement,
      insights: insights,
    );
    TrainingPackTemplateV2? tpl;
    if (boosterId != null) {
      await TrainingPackLibraryV2.instance.loadFromFolder();
      tpl = TrainingPackLibraryV2.instance.getById(boosterId);
    }

    if (!mounted) return;
    setState(() {
      _cluster = cluster;
      _evLoss = loss;
      _pack = tpl;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final tpl = _pack;
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final cluster = _cluster;
    final pack = _pack;
    if (cluster == null || pack == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cluster.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            cluster.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'EV lost: ${_evLoss.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Boost this area'),
            ),
          ),
        ],
      ),
    );
  }
}
