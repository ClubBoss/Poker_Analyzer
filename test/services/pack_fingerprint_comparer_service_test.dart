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
  test('areSimilar detects near duplicates', () {
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

    final fp1 = service.generatePackFingerprint(pack1);
    final fp2 = service.generatePackFingerprint(pack2);
    final fp3 = service.generatePackFingerprint(pack3);

    expect(service.areSimilar(fp1, fp2), isTrue);
    expect(service.areSimilar(fp1, fp3), isFalse);

    final duplicates = service.findDuplicates([pack1, pack2, pack3]);
    expect(duplicates.length, 1);
    expect(duplicates.first.a.id, 'p1');
    expect(duplicates.first.b.id, 'p2');
    expect(duplicates.first.similarity, greaterThanOrEqualTo(0.8));
  });
}

