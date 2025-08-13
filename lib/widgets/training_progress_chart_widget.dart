import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/training_session_fingerprint_timeline_service.dart';

/// Visualizes training progress over time showing accuracy and volume.
class TrainingProgressChartWidget extends StatefulWidget {
  const TrainingProgressChartWidget({
    super.key,
    this.service,
    this.dayRange,
  });

  /// Service used to load timeline data. Defaults to
  /// [TrainingSessionFingerprintTimelineService].
  final TrainingSessionFingerprintTimelineService? service;

  /// If provided, only show data from the last [dayRange] days.
  /// When `null`, shows all available data.
  final int? dayRange;

  @override
  State<TrainingProgressChartWidget> createState() =>
      _TrainingProgressChartWidgetState();
}

class _TrainingProgressChartWidgetState
    extends State<TrainingProgressChartWidget> {
  late final TrainingSessionFingerprintTimelineService _service;
  late Future<List<TrainingTimelineDaySummary>> _future;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? TrainingSessionFingerprintTimelineService();
    _future = _service.generateTimeline();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TrainingTimelineDaySummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var data = snapshot.data!;
        if (widget.dayRange != null) {
          final cutoff =
              DateTime.now().subtract(Duration(days: widget.dayRange!));
          data = data.where((e) => e.date.isAfter(cutoff)).toList();
        }
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }

        final accuracySpots = <FlSpot>[];
        final volumeSpots = <FlSpot>[];
        final dipIndices = <int>{};
        var maxVolume = 0;
        for (var i = 0; i < data.length; i++) {
          final s = data[i];
          final x = s.date.millisecondsSinceEpoch.toDouble();
          accuracySpots.add(FlSpot(x, s.avgAccuracy * 100));
          if (s.sessionCount > maxVolume) {
            maxVolume = s.sessionCount;
          }
          volumeSpots.add(FlSpot(x, s.sessionCount.toDouble()));
          if (i > 0) {
            final prev = data[i - 1].avgAccuracy;
            if (s.avgAccuracy < prev - 0.1) {
              dipIndices.add(i);
            }
          }
        }

        // scale volume to 0-100 for chart
        final scaledVolumeSpots = volumeSpots
            .map((e) => FlSpot(e.x, maxVolume == 0 ? 0 : e.y / maxVolume * 100))
            .toList();

        final allSpots = [...accuracySpots, ...scaledVolumeSpots];
        allSpots.sort((a, b) => a.x.compareTo(b.x));
        final minX = allSpots.first.x;
        final maxX = allSpots.last.x;

        final volumeInterval = (maxVolume / 4).ceil();
        final volumeIntervalScaled =
            maxVolume == 0 ? 0 : volumeInterval / maxVolume * 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: volumeIntervalScaled == 0
                            ? 1
                            : volumeIntervalScaled.toDouble(),
                        getTitlesWidget: (value, meta) {
                          final count = (value / 100 * maxVolume).round();
                          return Text(
                            count.toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: accuracySpots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.blue,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          final isDip = dipIndices.contains(index);
                          return FlDotCirclePainter(
                            radius: isDip ? 4 : 3,
                            color: isDip ? Colors.red : Colors.blue,
                          );
                        },
                      ),
                    ),
                    LineChartBarData(
                      spots: scaledVolumeSpots,
                      isCurved: true,
                      barWidth: 2,
                      color: Colors.green,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: const [
                _Legend(color: Colors.blue, text: 'Accuracy %'),
                _Legend(color: Colors.green, text: 'Volume'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
