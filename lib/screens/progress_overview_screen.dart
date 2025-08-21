import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/progress_forecast_service.dart';
import '../models/training_result.dart';
import '../widgets/ev_icm_trend_chart.dart';
import '../widgets/history/accuracy_chart.dart';
import '../widgets/history/average_accuracy_chart.dart';
import '../widgets/common/ev_icm_trend_chart.dart' as common;
import '../widgets/sync_status_widget.dart';
import '../theme/app_colors.dart';
import '../services/training_stats_service.dart';
import '../utils/responsive.dart';
import '../services/saved_hand_manager_service.dart';

class ProgressOverviewScreen extends StatefulWidget {
  static const route = '/progress_overview';
  const ProgressOverviewScreen({super.key});

  @override
  State<ProgressOverviewScreen> createState() => _ProgressOverviewScreenState();
}

class _ProgressOverviewScreenState extends State<ProgressOverviewScreen> {
  EvIcmTrendMode _mode = EvIcmTrendMode.weekly;

  List<TrainingResult> _sessions(List<ProgressEntry> history) {
    return [
      for (final e in history)
        TrainingResult(
          date: e.date,
          total: 0,
          correct: 0,
          accuracy: e.accuracy * 100,
        ),
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
        actions: [
          ToggleButtons(
            isSelected: [
              _mode == EvIcmTrendMode.weekly,
              _mode == EvIcmTrendMode.monthly,
            ],
            onPressed: (i) => setState(() => _mode = EvIcmTrendMode.values[i]),
            borderRadius: BorderRadius.circular(4),
            selectedColor: Colors.white,
            fillColor: Colors.blueGrey,
            color: Colors.white70,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Неделя'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Месяц'),
              ),
            ],
          ),
          SyncStatusIcon.of(context),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EvIcmTrendChart(
            mode: _mode,
            sessionDates: context.watch<TrainingStatsService>().sessionHistory(
                  context.watch<SavedHandManagerService>().hands,
                ),
          ),
          const SizedBox(height: 16),
          if (hasData) AccuracyChart(sessions: sessions) else _placeholder(),
          if (hasData) AverageAccuracyChart(sessions: sessions),
          if (hasData)
            common.EvIcmTrendChart(
              data: context.watch<ProgressForecastService>().evIcmSeries,
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: responsiveSize(context, 200),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Недостаточно данных',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
