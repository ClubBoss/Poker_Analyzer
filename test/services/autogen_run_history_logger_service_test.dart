import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:poker_analyzer/services/autogen_run_history_logger_service.dart';
import 'package:poker_analyzer/models/training_run_record.dart';

void main() {
  test('logs and retrieves run history', () async {
    final dir = await Directory.systemTemp.createTemp('run_history_test');
    final service = AutogenRunHistoryLoggerService(
      filePath: p.join(dir.path, 'history.json'),
    );

    const fmt = FormatMeta(spotsPerPack: 12, streets: 1, theoryRatio: 0.5);
    await service.logRun(
      generated: 10,
      rejected: 3,
      avgScore: 0.8,
      format: fmt,
    );
    await service.logRun(
      generated: 20,
      rejected: 5,
      avgScore: 0.9,
      format: fmt,
    );

    final history = await service.getHistory();
    expect(history.length, 2);
    expect(history[0].generated, 10);
    expect(history[1].avgQualityScore, closeTo(0.9, 1e-9));
    expect(history[0].format?.spotsPerPack, 12);
  });
}
