import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/decay_session_tag_impact_recorder.dart';

class DecayRecallInsightPanel extends StatefulWidget {
  final String tag;
  final bool initiallyExpanded;
  const DecayRecallInsightPanel({
    super.key,
    required this.tag,
    this.initiallyExpanded = false,
  });

  @override
  State<DecayRecallInsightPanel> createState() =>
      _DecayRecallInsightPanelState();
}

class _DecayRecallInsightPanelState extends State<DecayRecallInsightPanel> {
  late Future<_InsightData> _future;
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _future = _load();
  }

  Future<_InsightData> _load() async {
    final events = await DecaySessionTagImpactRecorder.instance
        .getRecentReinforcements(widget.tag);
    if (events.isEmpty) return _InsightData.empty();
    final now = DateTime.now();
    final last = events.first.timestamp;
    int c7 = 0;
    int c30 = 0;
    int c90 = 0;
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final data = List<double>.filled(30, 0);
    for (final e in events) {
      final diff = now.difference(e.timestamp).inDays;
      if (diff < 7) c7++;
      if (diff < 30) c30++;
      if (diff < 90) c90++;
      final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      if (d.isBefore(start)) break;
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < data.length) data[idx] += e.delta;
    }
    return _InsightData(
      last: last,
      count7: c7,
      count30: c30,
      count90: c90,
      deltas: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<_InsightData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Нет данных по повторениям',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        final maxVal =
            data.deltas.map((e) => e.abs()).fold<double>(0, math.max);
        final groups = <BarChartGroupData>[];
        for (var i = 0; i < data.deltas.length; i++) {
          final v = data.deltas[i];
          groups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: v,
                  width: 3,
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.7), accent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            ),
          );
        }
        final lastLabel =
            '${data.last.day.toString().padLeft(2, '0')}.${data.last.month.toString().padLeft(2, '0')}';
        final summary =
            'Последнее: $lastLabel · 7д ${data.count7} · 30д ${data.count30} · 90д ${data.count90}';
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            initiallyExpanded: _expanded,
            onExpansionChanged: (v) => setState(() => _expanded = v),
            title: Text(summary, style: const TextStyle(color: Colors.white)),
            collapsedIconColor: Colors.white,
            iconColor: Colors.white,
            textColor: Colors.white,
            childrenPadding: const EdgeInsets.all(12),
            children: [
              SizedBox(
                height: 40,
                child: BarChart(
                  BarChartData(
                    maxY: maxVal == 0 ? 1 : maxVal,
                    minY: 0,
                    alignment: BarChartAlignment.spaceBetween,
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: groups,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InsightData {
  final DateTime last;
  final int count7;
  final int count30;
  final int count90;
  final List<double> deltas;
  const _InsightData({
    required this.last,
    required this.count7,
    required this.count30,
    required this.count90,
    required this.deltas,
  });
  const _InsightData.empty()
      : last = DateTime(1970),
        count7 = 0,
        count30 = 0,
        count90 = 0,
        deltas = const [];
  bool get isEmpty => last.year == 1970;
}
