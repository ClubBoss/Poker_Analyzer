import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_mastery_service.dart';
import '../services/xp_tracker_service.dart';
import '../services/mistake_tag_insights_service.dart';
import '../services/mistake_cluster_analytics_service.dart';
import '../services/mistake_tag_cluster_service.dart';
import '../services/smart_review_service.dart';
import '../services/template_storage_service.dart';
import '../services/training_session_service.dart';
import '../models/mistake_tag_cluster.dart';
import '../models/mistake_insight.dart';
import '../models/mistake_tag.dart';
import '../models/v2/training_pack_template.dart';
import '../widgets/skill_card.dart';
import '../widgets/booster_packs_block.dart';
import '../widgets/booster_suggestion_block.dart';
import '../utils/responsive.dart';
import 'tag_insight_screen.dart';
import 'training_session_screen.dart';
import 'package:uuid/uuid.dart';

class SkillMapScreen extends StatefulWidget {
  const SkillMapScreen({super.key});

  @override
  State<SkillMapScreen> createState() => _SkillMapScreenState();
}

class _SkillMapScreenState extends State<SkillMapScreen> {
  bool _loading = true;
  Map<String, double> _data = {};
  Map<String, int> _xp = {};
  bool _weakFirst = true;
  List<ClusterAnalytics> _clusters = [];
  final Map<MistakeTagCluster, List<MistakeInsight>> _clusterInsights = {};
  double _maxClusterLoss = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final masteryService = context.read<TagMasteryService>();
    final xpService = context.read<XPTrackerService>();
    final insights = await const MistakeTagInsightsService().buildInsights(
      sortByEvLoss: true,
    );
    final clusters = const MistakeClusterAnalyticsService().compute(insights);
    const clusterSvc = MistakeTagClusterService();
    final byCluster = <MistakeTagCluster, List<MistakeInsight>>{};
    for (final i in insights) {
      final c = clusterSvc.getClusterForTag(i.tag);
      byCluster.putIfAbsent(c, () => []).add(i);
    }
    clusters.sort((a, b) => b.avgEvLoss.compareTo(a.avgEvLoss));
    final maxLoss = clusters.isEmpty
        ? 0.0
        : clusters.map((e) => e.avgEvLoss).reduce(max);
    final map = await masteryService.computeMastery(force: true);
    final xpMap = await xpService.getTotalXpPerTag();
    final entries = map.entries.toList();
    _sort(entries);
    setState(() {
      _data = {for (final e in entries) e.key: e.value};
      _xp = xpMap;
      _clusters = clusters;
      _clusterInsights
        ..clear()
        ..addAll(byCluster);
      _maxClusterLoss = maxLoss;
      _loading = false;
    });
  }

  void _sort(List<MapEntry<String, double>> list) {
    list.sort(
      (a, b) =>
          _weakFirst ? a.value.compareTo(b.value) : b.value.compareTo(a.value),
    );
  }

  void _toggleSort() {
    setState(() {
      _weakFirst = !_weakFirst;
      final entries = _data.entries.toList();
      _sort(entries);
      _data = {for (final e in entries) e.key: e.value};
    });
  }

  void _openTag(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TagInsightScreen(tag: tag)),
    );
  }

  Future<void> _reviewCluster(Set<MistakeTag> tags) async {
    final templates = context.read<TemplateStorageService>();
    var spots = await SmartReviewService.instance.getMistakeSpots(
      templates,
      context: context,
    );
    if (tags.isNotEmpty) {
      final allowed = tags.map((e) => e.name.toLowerCase()).toSet();
      spots = [
        for (final s in spots)
          if (s.tags.any((t) => allowed.contains(t.toLowerCase()))) s,
      ];
    }
    if (spots.isEmpty) return;
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

  Widget _clusterTile(ClusterAnalytics c) {
    final insights = _clusterInsights[c.cluster] ?? const <MistakeInsight>[];
    final ratio = _maxClusterLoss > 0
        ? (c.avgEvLoss / _maxClusterLoss).clamp(0.0, 1.0)
        : 0.0;
    final mastery = 1 - ratio;
    final color = Color.lerp(Colors.red, Colors.green, mastery) ?? Colors.red;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        title: Text(
          c.cluster.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avg EV loss: ${c.avgEvLoss.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mastery,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final i in insights)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${i.tag.label}: ${i.count} · ${i.evLoss.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        _reviewCluster(insights.map((e) => e.tag).toSet()),
                    child: const Text(
                      'Review',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isLandscape(context)
        ? (isCompactWidth(context) ? 6 : 8)
        : (isCompactWidth(context) ? 3 : 4);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Карта навыков'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _toggleSort,
            icon: Icon(_weakFirst ? Icons.arrow_downward : Icons.arrow_upward),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    for (final e in _data.entries)
                      SkillCard(
                        tag: e.key,
                        mastery: e.value,
                        totalXp: _xp[e.key] ?? 0,
                        onTap: () => _openTag(e.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final c in _clusters) _clusterTile(c),
                const SizedBox(height: 16),
                const BoosterSuggestionBlock(),
                const SizedBox(height: 16),
                const BoosterPacksBlock(),
              ],
            ),
    );
  }
}
