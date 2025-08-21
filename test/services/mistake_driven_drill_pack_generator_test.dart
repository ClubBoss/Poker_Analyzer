import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mistake_driven_drill_pack_generator.dart';
import 'package:poker_analyzer/services/mistake_history_query_service.dart';
import 'package:poker_analyzer/models/mistake_history_entry.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';

class _StubHistoryService extends MistakeHistoryQueryService {
  final List<MistakeHistoryEntry> entries;
  _StubHistoryService(this.entries)
      : super(
          loadSpottings: () async => [],
          resolveTags: (_) async => [],
          resolveStreet: (_) async => null,
        );
  @override
  Future<List<MistakeHistoryEntry>> queryMistakes({
    String? tag,
    String? street,
    String? spotIdPattern,
    int limit = 20,
  }) async {
    final list = List<MistakeHistoryEntry>.from(entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(limit).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates pack from recent unrecovered mistakes', () async {
    final history = _StubHistoryService([
      MistakeHistoryEntry(
        spotId: 'a',
        timestamp: DateTime(2023, 1, 3),
        decayStage: 'x',
        tag: 'T1',
        wasRecovered: false,
      ),
      MistakeHistoryEntry(
        spotId: 'b',
        timestamp: DateTime(2023, 1, 2),
        decayStage: 'x',
        tag: 'T2',
        wasRecovered: false,
      ),
      MistakeHistoryEntry(
        spotId: 'c',
        timestamp: DateTime(2023, 1, 1),
        decayStage: 'x',
        tag: 'T3',
        wasRecovered: true,
      ),
    ]);

    final spotMap = {
      'a': TrainingPackSpot(id: 'a', hand: HandData()),
      'b': TrainingPackSpot(id: 'b', hand: HandData()),
      'c': TrainingPackSpot(id: 'c', hand: HandData()),
    };

    final generator = MistakeDrivenDrillPackGenerator(
      history: history,
      loadSpot: (id) async => spotMap[id],
    );

    final pack = await generator.generate(limit: 5);
    expect(pack, isNotNull);
    expect(pack!.name, 'Fix Your Mistakes');
    expect(pack.meta['origin'], 'mistake-drill');
    expect(pack.spots.length, 2);
    expect(pack.spots.first.id, 'a');
  });
}
