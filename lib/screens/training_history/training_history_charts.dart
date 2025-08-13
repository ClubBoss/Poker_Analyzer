import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/history/accuracy_chart.dart';
import '../../widgets/history/session_accuracy_bar_chart.dart';
import 'training_history_view_model.dart';

class TrainingHistoryCharts extends StatelessWidget {
  const TrainingHistoryCharts({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingHistoryViewModel>();
    final filtered = vm.getFilteredHistory();
    final last7days = vm.history
        .where((r) =>
            r.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    return Column(
      children: [
        AccuracyChart(sessions: filtered),
        SessionAccuracyBarChart(sessions: last7days),
      ],
    );
  }
}
