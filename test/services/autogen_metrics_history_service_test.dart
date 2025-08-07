import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:poker_analyzer/services/autogen_metrics_history_service.dart';

void main() {
  test('records and loads history', () async {
    final dir = await Directory.systemTemp.createTemp('history_test');
    final service = AutogenMetricsHistoryService(
      filePath: p.join(dir.path, 'history.json'),
    );

    await service.recordRunMetrics(0.8, 60);
    await service.recordRunMetrics(0.9, 70);

    final history = await service.loadHistory();
    expect(history.length, 2);
    expect(history[0].avgQualityScore, 0.8);
    expect(history[1].acceptanceRate, 70);
  });

  test('getLastTwoRuns returns newest entries first', () async {
    final dir = await Directory.systemTemp.createTemp('history_test2');
    final service = AutogenMetricsHistoryService(
      filePath: p.join(dir.path, 'history.json'),
    );

    await service.recordRunMetrics(0.7, 50);
    await service.recordRunMetrics(0.8, 60);
    await service.recordRunMetrics(0.9, 70);

    final lastTwo = await service.getLastTwoRuns();
    expect(lastTwo.length, 2);
    expect(lastTwo[0].avgQualityScore, 0.9);
    expect(lastTwo[1].avgQualityScore, 0.8);
  });
}
