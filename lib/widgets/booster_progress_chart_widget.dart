import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/booster_stats_tracker_service.dart';

/// Displays accuracy progression for given [tags] based on booster stats.
class BoosterProgressChartWidget extends StatefulWidget {
  const BoosterProgressChartWidget({
    super.key,
    required this.tags,
    this.service,
    this.lastSessions,
    this.since,
  });

  /// Tags to visualize.
  final List<String> tags;

  /// Service used to load progress. Defaults to [BoosterStatsTrackerService].
  final BoosterStatsTrackerService? service;

  /// Limits to the last N sessions for each tag.
  final int? lastSessions;

  /// Only include progress after this date.
  final DateTime? since;

  @override
  State<BoosterProgressChartWidget> createState() =>
      _BoosterProgressChartWidgetState();
}

class _BoosterProgressChartWidgetState
    extends State<BoosterProgressChartWidget> {
  late final BoosterStatsTrackerService _service;
  late Future<Map<String, List<BoosterTagProgress>>> _future;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? BoosterStatsTrackerService();
    _future = _load();
  }

  Future<Map<String, List<BoosterTagProgress>>> _load() async {
    final map = <String, List<BoosterTagProgress>>{};
    for (final t in widget.tags) {
      var list = await _service.getProgressForTag(t);
      if (widget.since != null) {
        list =
            list.where((e) => !e.date.isBefore(widget.since!)).toList();
      }
      if (widget.lastSessions != null && list.length > widget.lastSessions!) {
        list = list.sublist(list.length - widget.lastSessions!);
      }
      map[t] = list;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<BoosterTagProgress>>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.values.every((e) => e.isEmpty)) {
          return const SizedBox.shrink();
        }

        final colors = Colors.primaries;
        var colorIndex = 0;
        final lines = <LineChartBarData>[];
        final legends = <Widget>[];
        final allSpots = <FlSpot>[];

        for (final entry in data.entries) {
          final color = colors[colorIndex % colors.length];
          final list = entry.value;
          final spots = <FlSpot>[];
          for (final p in list) {
            final x = p.date.millisecondsSinceEpoch.toDouble();
            spots.add(FlSpot(x, p.accuracy * 100));
          }
          allSpots.addAll(spots);
          lines.add(LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: color,
            dotData: const FlDotData(show: false),
          ));
          legends.add(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(entry.key),
            ],
          ));
          colorIndex++;
        }

        allSpots.sort((a, b) => a.x.compareTo(b.x));
        final minX = allSpots.first.x;
        final maxX = allSpots.last.x;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  minX: minX,
                  maxX: maxX,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 25,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: (maxX - minX) / 4,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: lines,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: legends),
          ],
        );
      },
    );
  }
}

