import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/progress_forecast_service.dart';
import '../widgets/progress_history_chart.dart';
import '../widgets/sync_status_widget.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class ProgressHistoryScreen extends StatelessWidget {
  static const route = '/progress_history';
  const ProgressHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasData =
        context.watch<ProgressForecastService>().history.length >= 2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('История EV/ICM'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hasData) const ProgressHistoryChart() else _placeholder(),
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
      child: const Text('Недостаточно данных',
          style: TextStyle(color: Colors.white70)),
    );
  }
}
