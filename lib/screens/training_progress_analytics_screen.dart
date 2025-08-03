import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_stats_service.dart';
import '../services/achievement_engine.dart';
import '../services/progress_forecast_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/responsive.dart';
import '../utils/context_extensions.dart';

class TrainingProgressAnalyticsScreen extends StatelessWidget {
  static const route = '/training/analytics';
  const TrainingProgressAnalyticsScreen({super.key});

  Future<void> _exportCsv(BuildContext context) async {
    final file = await context.read<ProgressForecastService>().exportForecastCsv();
    context.ifMounted(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: ${file.path.split('/').last}')),
      );
    });
  }

  Widget _chart(List<MapEntry<DateTime, int>> data, Color color) {
    if (data.length < 2) return SizedBox(height: responsiveSize(context, 200));
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value.toDouble()));
    }
    final step = (data.length / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (v) =>
                const FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval:
                    data.map((e) => e.value).reduce((a, b) => a > b ? a : b) / 4,
                reservedSize: 30,
                getTitlesWidget: (v, meta) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  if (i % step != 0 && i != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = data[i].key;
                  return Text(
                    '${d.month.toString().padLeft(2, '0')}.${(d.year % 100).toString().padLeft(2, '0')}',
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
              isCurved: false,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final achievements = context.watch<AchievementEngine>().achievements;
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Analytics'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final a in achievements)
                Column(
                  children: [
                    Icon(a.icon, color: a.level.color),
                    const SizedBox(height: 4),
                    Text('${a.progress}/${a.nextTarget}')
                  ],
                )
            ],
          ),
          const SizedBox(height: 12),
          _chart(stats.handsMonthly(12), accent),
          const SizedBox(height: 12),
          _chart(stats.sessionsMonthly(12), Colors.greenAccent),
          const SizedBox(height: 12),
          _chart(stats.mistakesMonthly(12), Colors.redAccent),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _exportCsv(context),
            child: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }
}
