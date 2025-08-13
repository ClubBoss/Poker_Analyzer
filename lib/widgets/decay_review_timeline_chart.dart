import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/tag_decay_forecast_service.dart';
import '../services/decay_session_tag_impact_recorder.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class DecayReviewTimelineChart extends StatefulWidget {
  final Map<String, TagDecayStats> stats;
  final List<String>? initialTags;
  const DecayReviewTimelineChart({
    super.key,
    required this.stats,
    this.initialTags,
  });

  @override
  State<DecayReviewTimelineChart> createState() =>
      _DecayReviewTimelineChartState();
}

class _DecayReviewTimelineChartState extends State<DecayReviewTimelineChart> {
  final Map<String, List<DateTime>> _events = {};
  late List<String> _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTags ?? widget.stats.keys.toList();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    final map = <String, List<DateTime>>{};
    for (final tag in _selected) {
      final events = await DecaySessionTagImpactRecorder.instance
          .getRecentReinforcements(tag);
      map[tag] = [for (final e in events) e.timestamp]..sort();
    }
    setState(() {
      _events.clear();
      _events.addAll(map);
      _loading = false;
    });
  }

  Future<void> _pickTags() async {
    final all = widget.stats.keys.toList()..sort();
    final current = Set<String>.from(_selected);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final checked = {for (final t in all) t: current.contains(t)};
        return AlertDialog(
          title: const Text('Select tags'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final t in all)
                        CheckboxListTile(
                          value: checked[t],
                          title: Text(t),
                          onChanged: (v) =>
                              setState(() => checked[t] = v ?? false),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                [
                  for (final e in checked.entries)
                    if (e.value) e.key
                ],
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() => _selected = result);
      await _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = _selected;
    if (_loading) {
      return SizedBox(
        height: responsiveSize(context, 200),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (tags.isEmpty) {
      return Container(
        height: responsiveSize(context, 200),
        alignment: Alignment.center,
        child: const Text('No tags selected',
            style: TextStyle(color: Colors.white70)),
      );
    }
    DateTime? minDate;
    DateTime? maxDate;
    for (final t in tags) {
      for (final d in _events[t] ?? []) {
        if (minDate == null || d.isBefore(minDate)) minDate = d;
        if (maxDate == null || d.isAfter(maxDate)) maxDate = d;
      }
      final next = widget.stats[t]?.nextReview;
      if (next != null) {
        if (minDate == null || next.isBefore(minDate)) minDate = next;
        if (maxDate == null || next.isAfter(maxDate)) maxDate = next;
      }
    }
    minDate ??= DateTime.now();
    maxDate ??= minDate.add(const Duration(days: 1));
    final totalDays =
        math.max(1, maxDate.difference(minDate).inDays.toDouble());

    final colors = [
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.yellowAccent,
      Colors.tealAccent,
    ];

    final bars = <LineChartBarData>[];
    final vertical = <VerticalLine>[];
    for (var i = 0; i < tags.length; i++) {
      final tag = tags[i];
      final color = colors[i % colors.length];
      final events = _events[tag] ?? [];
      final spots = [
        for (final d in events)
          FlSpot(d.difference(minDate).inDays.toDouble(), i.toDouble()),
      ];
      bars.add(
        LineChartBarData(
          spots: spots,
          color: color,
          barWidth: 0,
          isCurved: false,
          dotData: FlDotData(show: true, dotColor: color, dotSize: 3),
        ),
      );
      final next = widget.stats[tag]?.nextReview;
      if (next != null) {
        final x = next.difference(minDate).inDays.toDouble();
        vertical.add(
          VerticalLine(
            x: x,
            color: color,
            dashArray: [4, 2],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              style: const TextStyle(color: Colors.white70, fontSize: 8),
              labelResolver: (_) =>
                  '${next.day.toString().padLeft(2, '0')}.${next.month.toString().padLeft(2, '0')}',
            ),
          ),
        );
      }
    }
    final step = (totalDays / 6).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _pickTags,
            child: const Text('Select tags'),
          ),
        ),
        Container(
          height: responsiveSize(context, 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: totalDays,
              minY: -1,
              maxY: tags.length.toDouble(),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                verticalInterval: step,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white24, strokeWidth: 1),
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= tags.length)
                        return const SizedBox.shrink();
                      return Text(tags[i],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: step,
                    getTitlesWidget: (value, meta) {
                      final d = minDate!.add(Duration(days: value.toInt()));
                      return Text(
                        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
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
              lineBarsData: bars,
              extraLinesData: ExtraLinesData(verticalLines: vertical),
            ),
          ),
        ),
      ],
    );
  }
}
