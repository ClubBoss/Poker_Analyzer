import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../widgets/tag_insight_timeline.dart';

import '../services/progress_forecast_service.dart';
import '../services/skill_loss_detector.dart';
import '../services/tag_mastery_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/weakness_review_engine.dart';
import '../services/training_session_launcher.dart';
import '../services/saved_hand_manager_service.dart';
import '../widgets/tag_insight_header.dart';
import '../widgets/tag_drill_launcher.dart';

class TagInsightScreen extends StatefulWidget {
  final String tag;
  const TagInsightScreen({super.key, required this.tag});

  @override
  State<TagInsightScreen> createState() => _TagInsightScreenState();
}

class _TagInsightScreenState extends State<TagInsightScreen> {
  bool _loading = true;
  List<ProgressEntry> _series = [];
  String? _trend;
  WeaknessReviewItem? _reviewItem;
  List<String> _mistakes = [];
  double _skillLevel = 0;
  int _handsAnalyzed = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tag = widget.tag.toLowerCase();
    final forecast = context.read<ProgressForecastService>();
    final series = forecast.tagSeries(tag);
    final history = {
      tag: [for (final e in series) e.accuracy]
    };
    final losses = const SkillLossDetector().detect(history);
    final trend = losses.isNotEmpty ? losses.first.trend : null;

    final mastery = await context.read<TagMasteryService>().computeMastery();
    final skill = mastery[tag] ?? 0.0;

    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    final stats = <String, TrainingPackStat>{};
    for (final p in packs) {
      final s = await TrainingPackStatsService.getStats(p.id);
      if (s != null) stats[p.id] = s;
    }
    final deltas = await context.read<TagMasteryService>().computeDelta();
    final items = const WeaknessReviewEngine().analyze(
      attempts: const [],
      stats: stats,
      tagDeltas: deltas,
      allPacks: packs,
    );
    final review = items.firstWhereOrNull((e) => e.tag.toLowerCase() == tag);

    final hands = context.read<SavedHandManagerService>().hands;
    final taggedHands =
        hands.where((h) => h.tags.map((t) => t.toLowerCase()).contains(tag));
    final mistakes = [
      for (final h in taggedHands)
        if (h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h.name
    ]..sort((a, b) => b.compareTo(a));

    setState(() {
      _series = series;
      _trend = trend;
      _reviewItem = review;
      _mistakes = mistakes.take(3).toList();
      _skillLevel = skill;
      _handsAnalyzed = taggedHands.length;
      _loading = false;
    });
  }

  Future<void> _startReview() async {
    final item = _reviewItem;
    if (item == null) return;
    final packs = PackLibraryLoaderService.instance.library;
    final tpl = packs.firstWhereOrNull((p) => p.id == item.packId);
    if (tpl == null) return;
    await const TrainingSessionLauncher().launch(tpl);
  }

  Widget _mistakeList() {
    if (_mistakes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child:
            Text('Ошибок не найдено', style: TextStyle(color: Colors.white70)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Последние ошибки',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final m in _mistakes)
            Text(m, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tag: ${widget.tag}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TagInsightHeader(
                  tag: widget.tag,
                  skillLevel: _skillLevel,
                  trend: _trend ?? '',
                  handsAnalyzed: _handsAnalyzed,
                ),
                const SizedBox(height: 16),
                TagInsightTimeline(series: _series),
                const SizedBox(height: 16),
                _mistakeList(),
                if (_reviewItem != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startReview,
                    child: const Text('🔁 Review now'),
                  ),
                ],
                if (_skillLevel < 0.8 && _handsAnalyzed >= 5) ...[
                  const SizedBox(height: 16),
                  TagDrillLauncher(tag: widget.tag),
                ],
              ],
            ),
    );
  }
}
