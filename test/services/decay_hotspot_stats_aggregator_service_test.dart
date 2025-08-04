import 'package:test/test.dart';
import 'package:poker_analyzer/models/recall_failure_spotting.dart';
import 'package:poker_analyzer/models/recall_success_entry.dart';
import 'package:poker_analyzer/services/decay_hotspot_stats_aggregator_service.dart';
import 'package:poker_analyzer/models/decay_hotspot_stats.dart';

void main() {
  test('aggregates decay stats by tag and spotId', () async {
    final spottings = [
      RecallFailureSpotting(
        spotId: 's1',
        timestamp: DateTime(2023, 1, 1),
        decayStage: 'late',
      ),
      RecallFailureSpotting(
        spotId: 's1',
        timestamp: DateTime(2023, 1, 2),
        decayStage: 'early',
      ),
      RecallFailureSpotting(
        spotId: 's2',
        timestamp: DateTime(2023, 1, 3),
        decayStage: 'mid',
      ),
    ];

    final tags = {
      's1': ['TagA'],
      's2': ['TagB'],
    };

    final successes = [
      RecallSuccessEntry(tag: 'TagA', timestamp: DateTime(2023, 1, 4)),
    ];

    final service = DecayHotspotStatsAggregatorService(
      loadSpottings: () async => spottings,
      resolveTags: (id) async => tags[id] ?? [],
      loadSuccesses: () async => successes,
    );

    final report = await service.generateStats(top: 5);

    expect(report.topTags.length, 2);
    final tagA = report.topTags.firstWhere((e) => e.id == 'taga');
    expect(tagA.count, 2);
    expect(tagA.successRate, closeTo(1 / 3, 0.0001));
    expect(tagA.decayStageDistribution['late'], 1);
    expect(tagA.decayStageDistribution['early'], 1);
    expect(tagA.lastSeen, DateTime(2023, 1, 2));

    expect(report.topSpotIds.first.id, 's1');
    expect(report.topSpotIds.first.count, 2);
    expect(report.topSpotIds.first.decayStageDistribution['late'], 1);
  });
}

