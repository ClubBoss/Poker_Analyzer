import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/icm_weight_distributor.dart';

void main() {
  group('ICMWeightDistributor', () {
    test('distributes weights based on rarity', () {
      final spots = [
        TrainingPackSpot(id: '1', tags: ['x'], type: 'A'),
        TrainingPackSpot(id: '2', tags: ['y'], type: 'A'),
        TrainingPackSpot(id: '3', tags: ['x'], type: 'B'),
      ];

      ICMWeightDistributor().distribute(spots);

      final w1 = spots[0].meta['weight'] as double;
      final w2 = spots[1].meta['weight'] as double;
      final w3 = spots[2].meta['weight'] as double;

      expect(w1 + w2 + w3, closeTo(1.0, 1e-6));
      expect(w2, closeTo(0.375, 1e-6));
      expect(w3, closeTo(0.375, 1e-6));
      expect(w1, closeTo(0.25, 1e-6));
    });

    test('icmMap overrides by spot id', () {
      final spots = [
        TrainingPackSpot(id: '1', tags: ['x'], type: 'A'),
        TrainingPackSpot(id: '2', tags: ['y'], type: 'A'),
      ];

      ICMWeightDistributor().distribute(spots, icmMap: {'2': 5});

      final w1 = spots[0].meta['weight'] as double;
      final w2 = spots[1].meta['weight'] as double;

      expect(w1 + w2, closeTo(1.0, 1e-6));
      expect(w2, greaterThan(w1));
    });
  });
}
