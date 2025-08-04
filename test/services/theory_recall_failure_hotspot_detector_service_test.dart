import 'package:test/test.dart';

import 'package:poker_analyzer/models/recall_failure_log_entry.dart';
import 'package:poker_analyzer/services/theory_recall_failure_hotspot_detector_service.dart';

void main() {
  test('generateHotspotReport returns top tags and spotIds', () async {
    final logs = [
      RecallFailureLogEntry(tag: 'a', spotId: 's1', timestamp: DateTime.now()),
      RecallFailureLogEntry(tag: 'a', spotId: 's1', timestamp: DateTime.now()),
      RecallFailureLogEntry(tag: 'b', spotId: 's2', timestamp: DateTime.now()),
      RecallFailureLogEntry(tag: 'b', spotId: 's3', timestamp: DateTime.now()),
      RecallFailureLogEntry(tag: 'c', spotId: 's2', timestamp: DateTime.now()),
    ];

    final service = TheoryRecallFailureHotspotDetectorService(
      loadLogs: () async => logs,
    );

    final report = await service.generateHotspotReport(top: 2);

    expect(report.topTags.length, 2);
    expect(report.topTags.first.id, 'a');
    expect(report.topTags.first.count, 2);
    expect(report.topSpotIds.length, 2);
    expect(report.topSpotIds.first.id, 's1');
    expect(report.topSpotIds.first.count, 2);
  });
}
