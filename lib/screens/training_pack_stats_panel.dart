import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/result_entry.dart';

class TrainingPackStatsPanel extends StatelessWidget {
  final List<ResultEntry> results;

  const TrainingPackStatsPanel({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final total = results.length;
    final correct = results.where((r) => r.correct).length;
    final mistakes = total - correct;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: correct.toDouble(),
                    color: Colors.green,
                    title: total > 0
                        ? '${(correct * 100 / total).toStringAsFixed(0)}%'
                        : '0%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: mistakes.toDouble(),
                    color: Colors.red,
                    title: total > 0
                        ? '${(mistakes * 100 / total).toStringAsFixed(0)}%'
                        : '0%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Total hands: $total'),
          Text('Correct: $correct'),
          Text('Mistakes: $mistakes'),
        ],
      ),
    );
  }
}
