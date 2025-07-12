import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/training_stats_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../helpers/category_translations.dart';
import '../theme/app_colors.dart';
import '../widgets/common/animated_line_chart.dart';

class CategoryAnalyticsScreen extends StatelessWidget {
  static const route = '/category_analytics';
  const CategoryAnalyticsScreen({super.key});

  Widget _chart(List<MapEntry<DateTime, double>> ev,
      List<MapEntry<DateTime, double>> icm) {
    final dates = {
      ...ev.map((e) => e.key),
      ...icm.map((e) => e.key)
    }.toList()
      ..sort();
    if (dates.length < 2) return const SizedBox(height: 200);
    final evMap = {for (final e in ev) e.key: e.value};
    final icmMap = {for (final e in icm) e.key: e.value};
    final spotsEv = <FlSpot>[];
    final spotsIcm = <FlSpot>[];
    double minY = 0;
    double maxY = 0;
    for (var i = 0; i < dates.length; i++) {
      final d = dates[i];
      final v1 = evMap[d];
      final v2 = icmMap[d];
      if (v1 != null) {
        spotsEv.add(FlSpot(i.toDouble(), v1));
        if (v1 < minY) minY = v1;
        if (v1 > maxY) maxY = v1;
      }
      if (v2 != null) {
        spotsIcm.add(FlSpot(i.toDouble(), v2));
        if (v2 < minY) minY = v2;
        if (v2 > maxY) maxY = v2;
      }
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final interval = (maxY - minY) / 4;
    final step = (dates.length / 6).ceil();
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedLineChart(
        data: LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
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
                  if (i < 0 || i >= dates.length) return const SizedBox.shrink();
                  if (i % step != 0 && i != dates.length - 1) {
                    return const SizedBox.shrink();
                  }
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
              spots: spotsEv,
              color: AppColors.evPre,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsIcm,
              color: AppColors.icmPre,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final hands = context.watch<SavedHandManagerService>().hands;
    final categories = <String>{
      for (final h in hands)
        if (h.category != null && h.category!.isNotEmpty) h.category!
    }.toList()
      ..sort();
    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Динамика категории'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Нет данных', style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Динамика категории'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final ev = stats.categoryEvSeries(hands, cat);
          final icm = stats.categoryIcmSeries(hands, cat);
          final name = translateCategory(cat).isEmpty
              ? 'Без категории'
              : translateCategory(cat);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _chart(ev, icm),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
