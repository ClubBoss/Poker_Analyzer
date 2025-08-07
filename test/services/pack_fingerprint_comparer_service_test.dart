import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/services/pack_fingerprint_comparer_service.dart';

TrainingPackSpot _spot(String id, List<String> board, List<String> actions) {
  final hand = HandData(
    board: board,
    actions: {
      0: [for (final a in actions) ActionEntry(0, 0, a)],
    },
  );
  return TrainingPackSpot(id: id, hand: hand, board: board);
}

void main() {
  test('computeSimilarity detects near duplicates', () {
    final service = const PackFingerprintComparerService();
    final pack1 = TrainingPackModel(
      id: 'p1',
      title: 'A',
      spots: [
        _spot('s1', ['Ah', 'Kd', 'Qc'], ['push', 'call']),
        _spot('s2', ['2c', '3d', '4h'], ['bet', 'fold']),
      ],
      tags: ['tag1'],
    );
    final pack2 = TrainingPackModel(
      id: 'p2',
      title: 'B',
      spots: [
        _spot('s3', ['Ah', 'Kd', 'Qc'], ['push', 'call']),
        _spot('s4', ['2c', '3d', '4h'], ['bet', 'fold']),
      ],
      tags: ['tag1'],
    );
    final pack3 = TrainingPackModel(
      id: 'p3',
      title: 'C',
      spots: [
        _spot('s5', ['5c', '6d', '7h'], ['raise', 'fold']),
      ],
      tags: ['tag2'],
    );

    final sim12 = service.computeSimilarity(pack1, pack2);
    final sim13 = service.computeSimilarity(pack1, pack3);

    expect(sim12, greaterThanOrEqualTo(0.8));
    expect(sim13, lessThan(0.8));

    final matches = service.findSimilarPacks(pack1, [pack1, pack2, pack3]);
    expect(matches.length, 1);
    expect(matches.first.pack.id, 'p2');
    expect(matches.first.similarity, sim12);
  });

  test('findDuplicates returns similar pairs', () {
    final service = const PackFingerprintComparerService();
    final pack1 = TrainingPackModel(
      id: 'p1',
      title: 'A',
      spots: [
        _spot('s1', ['Ah', 'Kd', 'Qc'], ['push', 'call']),
      ],
      tags: ['tag1'],
    );
    final pack2 = TrainingPackModel(
      id: 'p2',
      title: 'B',
      spots: [
        _spot('s2', ['Ah', 'Kd', 'Qc'], ['push', 'call']),
      ],
      tags: ['tag1'],
    );
    final pack3 = TrainingPackModel(
      id: 'p3',
      title: 'C',
      spots: [
        _spot('s3', ['2c', '3d', '4h'], ['bet', 'fold']),
      ],
      tags: ['tag2'],
    );

    final results = service.findDuplicates([pack1, pack2, pack3]);
    expect(results.length, 1);
    final pair = results.first;
    expect({pair.a.id, pair.b.id}, containsAll(['p1', 'p2']));
  });
}

