import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_mastery_service.dart';
import '../services/tag_mastery_history_service.dart';
import '../services/xp_tracker_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/pack_unlocking_rules_engine.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../widgets/tag_progress_sparkline.dart';
import '../widgets/tag_training_heatmap.dart';
import '../widgets/decay_recall_insight_panel.dart';
import '../widgets/training_pack_template_card.dart';
import '../screens/training_session_screen.dart';
import '../services/training_session_service.dart';

class TagSkillDetailScreen extends StatefulWidget {
  final String tag;
  const TagSkillDetailScreen({super.key, required this.tag});

  @override
  State<TagSkillDetailScreen> createState() => _TagSkillDetailScreenState();
}

class _TagSkillDetailScreenState extends State<TagSkillDetailScreen> {
  bool _loading = true;
  double _mastery = 0;
  int _totalXp = 0;
  double _trend = 0;
  final List<TrainingPackTemplateV2> _packs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tag = widget.tag.toLowerCase();
    final masteryService = context.read<TagMasteryService>();
    final masteryMap = await masteryService.computeMastery();
    final xpService = context.read<XPTrackerService>();
    final xpMap = await xpService.getTotalXpPerTag();
    final histService = context.read<TagMasteryHistoryService>();
    final weekly = await histService.getWeeklyTotals();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    final packs = <TrainingPackTemplateV2>[];
    for (final p in library) {
      if (!p.tags.map((e) => e.toLowerCase()).contains(tag)) continue;
      if (await PackUnlockingRulesEngine.instance.isUnlocked(p)) {
        packs.add(p);
      }
    }
    final data = weekly[tag];
    double trend = 0;
    if (data != null && data.length >= 2) {
      final vals = data.values.toList();
      final last = vals.last.toDouble();
      final prev = vals[vals.length - 2].toDouble();
      if (prev > 0) trend = (last - prev) / prev;
    }
    setState(() {
      _mastery = masteryMap[tag] ?? 0;
      _totalXp = xpMap[tag] ?? 0;
      _trend = trend;
      _packs
        ..clear()
        ..addAll(packs);
      _loading = false;
    });
  }

  Future<void> _startPack(TrainingPackTemplateV2 tpl) async {
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  Widget _buildHeader() {
    final color = Color.lerp(Colors.red, Colors.green, _mastery) ?? Colors.red;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧠 Навык: ${widget.tag}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Mastery: ${(_mastery * 100).round()}% · XP: $_totalXp',
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    final arrow = _trend >= 0 ? Icons.arrow_upward : Icons.arrow_downward;
    final color = _trend >= 0 ? Colors.green : Colors.red;
    final pct = (_trend.abs() * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TagProgressSparkline(tag: widget.tag),
              const SizedBox(width: 8),
              if (_trend != 0)
                Row(
                  children: [
                    Icon(arrow, size: 16, color: color),
                    const SizedBox(width: 2),
                    Text('$pct%', style: TextStyle(color: color)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          TagTrainingHeatmap(tag: widget.tag),
        ],
      ),
    );
  }

  Widget _buildPacks() {
    if (_packs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '📦 Пакеты для тренировки',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => SizedBox(
              width: 200,
              child: TrainingPackTemplateCard(
                template: _packs[i],
                onTap: () => _startPack(_packs[i]),
              ),
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: _packs.length,
          ),
        ),
      ],
    );
  }

  Widget _buildRecent() {
    return DecayRecallInsightPanel(tag: widget.tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🧠 Навык: ${widget.tag}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildHeader(),
                _buildHistory(),
                _buildPacks(),
                _buildRecent(),
              ],
            ),
    );
  }
}
