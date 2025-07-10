import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/progress_forecast_service.dart';
import '../models/training_result.dart';
import '../widgets/daily_ev_icm_chart.dart';
import '../widgets/common/accuracy_chart.dart';
import '../widgets/common/average_accuracy_chart.dart';
import '../widgets/sync_status_widget.dart';
import '../theme/app_colors.dart';

class ProgressOverviewScreen extends StatelessWidget {
  static const route = '/progress_overview';
  const ProgressOverviewScreen({super.key});

  List<TrainingResult> _sessions(List<ProgressEntry> history) {
    return [
      for (final e in history)
        TrainingResult(
          date: e.date,
          total: 0,
          correct: 0,
          accuracy: e.accuracy * 100,
        )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ProgressForecastService>().history;
    final sessions = _sessions(history);
    final hasData = sessions.length >= 2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Overview'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DailyEvIcmChart(),
          const SizedBox(height: 16),
          if (hasData) AccuracyChart(sessions: sessions) else _placeholder(),
          if (hasData) AverageAccuracyChart(sessions: sessions),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Недостаточно данных',
          style: TextStyle(color: Colors.white70)),
    );
  }
}
