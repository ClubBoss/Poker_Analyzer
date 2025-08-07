import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:poker_analyzer/services/pack_generation_metrics_tracker_service.dart';

void main() {
  test('records and retrieves metrics', () async {
    final dir = await Directory.systemTemp.createTemp('metrics_test');
    final tracker = PackGenerationMetricsTrackerService(
      filePath: p.join(dir.path, 'metrics.json'),
    );

    await tracker.recordGenerationResult(score: 0.8, accepted: true);
    await tracker.recordGenerationResult(score: 0.6, accepted: false);

    final metrics = await tracker.getMetrics();
    expect(metrics['generatedCount'], 1);
    expect(metrics['rejectedCount'], 1);
    expect(metrics['avgQualityScore'], closeTo(0.7, 1e-9));
    expect(metrics['lastRunTimestamp'], isNotEmpty);

    await tracker.clearMetrics();
    final cleared = await tracker.getMetrics();
    expect(cleared['generatedCount'], 0);
    expect(cleared['rejectedCount'], 0);
    expect(cleared['avgQualityScore'], 0.0);
  });
}
