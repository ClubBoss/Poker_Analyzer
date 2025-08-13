import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'animated_line_chart.dart';

import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';

class SessionVolumeAccuracyPoint {
  final DateTime date;
  final double accuracy;
  final int hands;

  SessionVolumeAccuracyPoint(this.date, this.accuracy, this.hands);
}

class SessionVolumeAccuracyChart extends StatelessWidget {
  final List<SessionVolumeAccuracyPoint> sessions;

  const SessionVolumeAccuracyChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.length < 2) {
      return const SizedBox.shrink();
    }

    final sorted = [...sessions]..sort((a, b) => a.date.compareTo(b.date));
    final accuracySpots = <FlSpot>[];
    final volumeSpots = <FlSpot>[];
    int maxVolume = 0;
    for (var i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      accuracySpots.add(FlSpot(i.toDouble(), s.accuracy));
      volumeSpots.add(FlSpot(i.toDouble(), s.hands.toDouble()));
      if (s.hands > maxVolume) maxVolume = s.hands;
    }
    final scaledVolumeSpots = [
      for (final spot in volumeSpots)
        FlSpot(
          spot.x,
          maxVolume > 0 ? spot.y / maxVolume * 100 : 0,
        )
    ];

    final step = (sorted.length / 6).ceil();

    const double volumeInterval = 20;

    final accuracyLine = LineChartBarData(
      spots: accuracySpots,
      isCurved: true,
      color: AppColors.accent,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    final volumeLine = LineChartBarData(
      spots: scaledVolumeSpots,
      isCurved: true,
      color: Colors.lightBlueAccent,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: responsiveSize(context, 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedLineChart(
          data: LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) =>
                  const FlLine(color: Colors.white24, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: volumeInterval,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final v = (value / 100 * maxVolume).round();
                    return Text(
                      v.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= sorted.length) {
                      return const SizedBox.shrink();
                    }
                    if (index % step != 0 && index != sorted.length - 1) {
                      return const SizedBox.shrink();
                    }
                    final d = sorted[index].date;
                    final label =
                        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                    return Text(
                      label,
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
            lineBarsData: [accuracyLine, volumeLine],
          ),
        ),
      ),
    );
  }
}
