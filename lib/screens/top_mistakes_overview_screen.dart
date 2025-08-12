import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';

class TopMistakesOverviewScreen extends StatelessWidget {
  static const route = '/training/analytics/top-mistakes';
  const TopMistakesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = context.read<TrainingPackStorageService>().packs.where((p) => !p.isBuiltIn);
    final Map<String, int> counts = {};
    for (final p in packs) {
      for (final h in p.hands) {
        final dynamic d = h;
        final list = d.mistakes as List?;
        if (list == null) continue;
        for (final m in list) {
          if (m is Map) {
            final key = (m['type'] ?? m['tag'])?.toString();
            if (key != null && key.isNotEmpty) {
              counts[key] = (counts[key] ?? 0) + 1;
            }
          }
        }
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final labels = [for (final e in entries) e.key];
    final values = [for (final e in entries) e.value];
    final maxCount = values.isEmpty ? 0 : values.reduce(max);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < values.length; i++) {
      const color = Colors.redAccent;
      groups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: values[i].toDouble(),
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ]),
      );
    }
    double interval = 1;
    if (maxCount > 5) interval = (maxCount / 5).ceilToDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Частые ошибки'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: entries.isEmpty
          ? const Center(child: Text('Нет данных', style: TextStyle(color: Colors.white70)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 240,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BarChart(
                  BarChartData(
                    maxY: maxCount.toDouble(),
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) =>
                          const FlLine(color: Colors.white24, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
                          reservedSize: 30,
                          getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                            final text = labels[i];
                            return Transform.rotate(
                              angle: -pi / 4,
                              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
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
                    barGroups: groups,
                  ),
                ),
              ),
            ),
    );
  }
}
