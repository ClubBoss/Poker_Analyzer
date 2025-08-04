import 'package:test/test.dart';
import 'package:poker_analyzer/models/recall_failure_spotting.dart';
import 'package:poker_analyzer/models/recall_success_entry.dart';
import 'package:poker_analyzer/services/mistake_history_query_service.dart';

void main() {
  test('filters by tag, street and pattern and marks recovery', () async {
    final spottings = [
      RecallFailureSpotting(
        spotId: 's1',
        timestamp: DateTime(2023, 1, 1),
        decayStage: 'early',
      ),
      RecallFailureSpotting(
        spotId: 's2',
        timestamp: DateTime(2023, 1, 3),
        decayStage: 'mid',
      ),
      RecallFailureSpotting(
        spotId: 'x3',
        timestamp: DateTime(2023, 1, 2),
        decayStage: 'late',
      ),
    ];

    final tags = {
      's1': ['TagA'],
      's2': ['TagB'],
      'x3': ['TagA'],
    };

    final streets = {
      's1': 'flop',
      's2': 'turn',
      'x3': 'flop',
    };

    final successes = [
      RecallSuccessEntry(tag: 'TagA', timestamp: DateTime(2023, 1, 4)),
    ];

    final service = MistakeHistoryQueryService(
      loadSpottings: () async => spottings,
      resolveTags: (id) async => tags[id] ?? [],
      resolveStreet: (id) async => streets[id],
      loadSuccesses: () async => successes,
    );

    final res = await service.queryMistakes(
      tag: 'TagA',
      street: 'flop',
      spotIdPattern: 's',
      limit: 5,
    );

    expect(res.length, 1);
    expect(res.first.spotId, 's1');
    expect(res.first.wasRecovered, true);
  });

  test('applies limit and orders by timestamp', () async {
    final spottings = [
      RecallFailureSpotting(
        spotId: 'a',
        timestamp: DateTime(2023, 1, 1),
        decayStage: 'early',
      ),
      RecallFailureSpotting(
        spotId: 'b',
        timestamp: DateTime(2023, 1, 3),
        decayStage: 'mid',
      ),
      RecallFailureSpotting(
        spotId: 'c',
        timestamp: DateTime(2023, 1, 2),
        decayStage: 'late',
      ),
    ];

    final tags = {
      'a': ['T'],
      'b': ['T'],
      'c': ['T'],
    };

    final service = MistakeHistoryQueryService(
      loadSpottings: () async => spottings,
      resolveTags: (id) async => tags[id] ?? [],
      resolveStreet: (id) async => null,
      loadSuccesses: () async => [],
    );

    final res = await service.queryMistakes(tag: 'T', limit: 2);

    expect(res.length, 2);
    expect(res[0].spotId, 'b');
    expect(res[1].spotId, 'c');
  });
}

