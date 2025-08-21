import '../models/recall_failure_log_entry.dart';
import '../models/recall_hotspot_report.dart';

typedef RecallFailureLogLoader = Future<List<RecallFailureLogEntry>> Function();

class TheoryRecallFailureHotspotDetectorService {
  final RecallFailureLogLoader loadLogs;

  const TheoryRecallFailureHotspotDetectorService({required this.loadLogs});

  Future<RecallHotspotReport> generateHotspotReport({int top = 5}) async {
    if (top <= 0) {
      return const RecallHotspotReport(topTags: [], topSpotIds: []);
    }
    final logs = await loadLogs();
    final tagCounts = <String, int>{};
    final spotCounts = <String, int>{};
    for (final log in logs) {
      final tag = log.tag?.trim().toLowerCase();
      if (tag != null && tag.isNotEmpty) {
        tagCounts.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
      final spot = log.spotId?.trim();
      if (spot != null && spot.isNotEmpty) {
        spotCounts.update(spot, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final tags = tagCounts.entries
        .map((e) => RecallHotspotEntry(id: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final spots = spotCounts.entries
        .map((e) => RecallHotspotEntry(id: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return RecallHotspotReport(
      topTags: tags.take(top).toList(),
      topSpotIds: spots.take(top).toList(),
    );
  }
}
