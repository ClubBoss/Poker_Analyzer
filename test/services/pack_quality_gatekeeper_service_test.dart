import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/pack_quality_gatekeeper_service.dart';

void main() {
  group('PackQualityGatekeeperService', () {
    test('rejects packs below threshold', () {
      final pack = TrainingPackModel(
        id: 'p1',
        title: 'Low',
        spots: const [],
        metadata: {'qualityScore': 0.5},
      );
      const gatekeeper = PackQualityGatekeeperService();
      final result = gatekeeper.isQualityAcceptable(pack, minScore: 0.7);
      expect(result, isFalse);
    });

    test('computes score when missing and accepts above threshold', () {
      final spots = [
        TrainingPackSpot(
          id: '1',
          tags: ['a', 'b'],
          board: ['Ah', 'Kd', 'Qs'],
          correctAction: 'fold',
          theoryRefs: ['T1'],
        ),
        TrainingPackSpot(
          id: '2',
          tags: ['a'],
          board: ['2h', '3d', '5c'],
          correctAction: 'call',
          theoryRefs: ['T2'],
        ),
      ];
      final pack = TrainingPackModel(id: 'p2', title: 'High', spots: spots);
      const gatekeeper = PackQualityGatekeeperService();
      final result = gatekeeper.isQualityAcceptable(pack, minScore: 0.7);
      expect(result, isTrue);
      expect(pack.metadata['qualityScore'], isNotNull);
    });
  });
}
