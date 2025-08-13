import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:poker_analyzer/services/autogen_real_time_stats_refresher_service.dart';
import 'package:poker_analyzer/services/autogen_run_history_logger_service.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/models/autogen_status.dart';
import 'package:poker_analyzer/models/training_run_record.dart';

void main() {
  test('emits ticks only while running', () async {
    final dir = await Directory.systemTemp.createTemp('realtime_stats_test');
    final logger = AutogenRunHistoryLoggerService(
      filePath: p.join(dir.path, 'history.json'),
    );
    await logger.logRun(
        generated: 1,
        rejected: 0,
        avgScore: 0.5,
        format:
            const FormatMeta(spotsPerPack: 12, streets: 1, theoryRatio: 0.5));

    final status = AutogenStatusDashboardService.instance;
    final refresher = AutogenRealTimeStatsRefresherService(
      historyService: logger,
      statusService: status,
      interval: const Duration(milliseconds: 50),
    );

    final initial = refresher.notifier.value;
    await Future.delayed(const Duration(milliseconds: 120));
    expect(refresher.notifier.value, initial);

    status.update('pipeline', const AutogenStatus(isRunning: true));
    await Future.delayed(const Duration(milliseconds: 120));
    final runningValue = refresher.notifier.value;
    expect(runningValue.isAfter(initial), isTrue);

    status.update('pipeline', const AutogenStatus(isRunning: false));
    final stoppedValue = refresher.notifier.value;
    await Future.delayed(const Duration(milliseconds: 120));
    expect(refresher.notifier.value, stoppedValue);

    refresher.dispose();
  });
}
