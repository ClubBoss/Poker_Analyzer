import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/decay_retention_summary.dart';
import '../services/decay_retention_summary_service.dart';
import '../services/inbox_booster_delivery_controller.dart';

class DecayStatsDashboardScreen extends StatefulWidget {
  static const route = '/decay_stats_dashboard';
  const DecayStatsDashboardScreen({super.key});

  @override
  State<DecayStatsDashboardScreen> createState() => _DecayStatsDashboardScreenState();
}

class _DecayStatsDashboardScreenState extends State<DecayStatsDashboardScreen> {
  bool _loading = true;
  DecayRetentionSummary? _summary;
  Map<String, double> _scores = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = DecayRetentionSummaryService();
    final summary = await service.getSummary();
    final forecasts = await service.forecastService.getAllForecasts();
    final sorted = forecasts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = <String, double>{};
    for (final e in sorted.take(10)) {
      top[e.key] = e.value;
    }
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _scores = top;
      _loading = false;
    });
  }

  Future<void> _reviewNow() async {
    await InboxBoosterDeliveryController().maybeTriggerBoosterInbox();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Review triggered')));
  }

  Widget _summarySection() {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Забывание: ${(s.averageDecay * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Забытых тегов: ${s.decayedTags}/${s.totalTags}',
              style: const TextStyle(color: Colors.white70)),
          if (s.topForgotten.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Топ: ${s.topForgotten.join(', ')}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  Widget _barChart() {
    if (_scores.isEmpty) return const SizedBox.shrink();
    final tags = _scores.keys.toList();
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < tags.length; i++) {
      final value = (_scores[tags[i]] ?? 0) * 100;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [Colors.orangeAccent, Colors.redAccent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          maxY: 100,
          minY: 0,
          barGroups: groups,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= tags.length) return const SizedBox.shrink();
                  final tag = tags[idx];
                  return Transform.rotate(
                    angle: -1.5708,
                    child: Text(tag, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _decayedList() {
    if (_scores.isEmpty) return const SizedBox.shrink();
    final entries = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Забытые теги',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(color: Colors.white70)),
                Text('${(e.value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decay Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _summarySection(),
                const SizedBox(height: 16),
                _barChart(),
                const SizedBox(height: 16),
                _decayedList(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _reviewNow,
                  child: const Text('Запустить повторение'),
                ),
              ],
            ),
    );
  }
}
