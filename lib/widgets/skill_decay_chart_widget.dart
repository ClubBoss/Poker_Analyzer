import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/decay_tag_retention_tracker_service.dart';

/// Visualizes decay level over time for a set of tags.
class SkillDecayChartWidget extends StatefulWidget {
  const SkillDecayChartWidget({super.key, this.tags, this.days = 30});

  /// Tags to show. If null, the most decayed tags are fetched automatically.
  final List<String>? tags;

  /// Number of days to display.
  final int days;

  @override
  State<SkillDecayChartWidget> createState() => _SkillDecayChartWidgetState();
}

class _SkillDecayChartWidgetState extends State<SkillDecayChartWidget> {
  final _service = const DecayTagRetentionTrackerService();
  late Future<Map<String, List<FlSpot>>> _future;
  bool _relative = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, List<FlSpot>>> _load() async {
    final tags = widget.tags ??
        (await _service.getMostDecayedTags(3)).map((e) => e.key).toList();
    final now = DateTime.now();
    final start = now.subtract(Duration(days: widget.days));
    final map = <String, List<FlSpot>>{};
    for (final tag in tags) {
      final review = await _service.getLastTheoryReview(tag);
      final booster = await _service.getLastBoosterCompletion(tag);
      DateTime? last;
      if (review != null && booster != null) {
        last = review.isAfter(booster) ? review : booster;
      } else {
        last = review ?? booster;
      }
      final spots = <FlSpot>[];
      for (var i = 0; i <= widget.days; i++) {
        final date = start.add(Duration(days: i));
        final daysSince =
            last == null ? 100.0 : date.difference(last).inDays.toDouble();
        final retention = (1 - daysSince / 100).clamp(0.0, 1.0) * 100;
        spots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), retention));
      }
      map[tag] = spots;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<FlSpot>>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) return const SizedBox.shrink();

        final colors = Colors.primaries;
        final lines = <LineChartBarData>[];
        final legends = <Widget>[];
        double? minX;
        double? maxX;
        var colorIndex = 0;

        for (final entry in data.entries) {
          final color = colors[colorIndex % colors.length];
          var spots = entry.value;
          if (_relative && spots.isNotEmpty) {
            final base = spots.first.y;
            spots = [
              for (final s in spots)
                FlSpot(s.x, base == 0 ? 0 : s.y / base * 100)
            ];
          }
          if (spots.isNotEmpty) {
            minX = minX == null || spots.first.x < minX ? spots.first.x : minX;
            maxX = maxX == null || spots.last.x > maxX ? spots.last.x : maxX;
          }
          lines.add(LineChartBarData(
            spots: spots,
            isCurved: false,
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

        minX ??= 0;
        maxX ??= 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Relative', style: TextStyle(fontSize: 12)),
                Switch(
                  value: _relative,
                  onChanged: (v) => setState(() => _relative = v),
                ),
              ],
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  minX: minX,
                  maxX: maxX,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
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
                            '${date.month}/${date.day}',
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
