import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'package:fl_chart/fl_chart.dart';

import '../services/progress_forecast_service.dart';
import '../services/skill_loss_detector.dart';
import '../services/tag_mastery_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/weakness_review_engine.dart';
import '../services/training_session_launcher.dart';
import '../services/saved_hand_manager_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tag = widget.tag.toLowerCase();
    final forecast = context.read<ProgressForecastService>();
    final series = forecast.tagSeries(tag);
    final history = {tag: [for (final e in series) e.accuracy]};
    final losses = const SkillLossDetector().detect(history);
    final trend = losses.isNotEmpty ? losses.first.trend : null;

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
    final mistakes = [
      for (final h in hands.where((h) => h.tags.map((t) => t.toLowerCase()).contains(tag)))
        if (h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() != h.gtoAction!.trim().toLowerCase())
          h.name
    ]
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      _series = series;
      _trend = trend;
      _reviewItem = review;
      _mistakes = mistakes.take(3).toList();
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

  Widget _chart() {
    final dates = _series.map((e) => e.date).toList();
    if (dates.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Недостаточно данных', style: TextStyle(color: Colors.white70)),
      );
    }
    final spots = <FlSpot>[];
    double minY = 1, maxY = 0;
    for (var i = 0; i < _series.length; i++) {
      final a = _series[i].accuracy;
      spots.add(FlSpot(i.toDouble(), a));
      if (a < minY) minY = a;
      if (a > maxY) maxY = a;
    }
    if (minY == maxY) {
      minY -= 0.1;
      maxY += 0.1;
    }
    final interval = ((maxY - minY) / 4).clamp(0.05, 1.0);
    final step = (_series.length / 6).ceil();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 30,
                getTitlesWidget: (v, meta) => Text(
                  (v * 100).toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= dates.length) return const SizedBox.shrink();
                  if (i % step != 0 && i != dates.length - 1) return const SizedBox.shrink();
                  final d = dates[i];
                  return Text(
                    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.white24),
              bottom: BorderSide(color: Colors.white24),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: Colors.orangeAccent,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mistakeList() {
    if (_mistakes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Ошибок не найдено', style: TextStyle(color: Colors.white70)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Последние ошибки', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final m in _mistakes)
            Text(m, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _trend != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_trend!, style: const TextStyle(fontSize: 12)),
          )
        : const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: Text('Tag: ${widget.tag}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Text('Навык: ${widget.tag}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    badge,
                  ],
                ),
                const SizedBox(height: 16),
                _chart(),
                const SizedBox(height: 16),
                _mistakeList(),
                if (_reviewItem != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startReview,
                    child: const Text('🔁 Review now'),
                  ),
                ],
              ],
            ),
    );
  }
}
