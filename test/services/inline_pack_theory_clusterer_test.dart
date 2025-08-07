import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/inline_pack_theory_clusterer.dart';

void main() {
  group('InlinePackTheoryClusterer', () {
    test('clusters spots and injects theory notes', () {
      final spots = [
        TrainingPackSpot(id: 's1', tags: ['sb']),
        TrainingPackSpot(id: 's2', tags: ['sb']),
        TrainingPackSpot(id: 's3', tags: ['bb']),
      ];
      final model = TrainingPackModel(id: 'p1', title: 'Pack', spots: spots);
      final clusterer = InlinePackTheoryClusterer();

      final output = clusterer.clusterWithTheory(model);

      expect(output.spots.length, 5);
      expect(output.spots[0].isTheoryNote, isTrue);
      expect(output.spots[0].note, 'In this section, we cover [sb] situations...');
      expect(output.spots[1].id, 's1');
      expect(output.spots[2].id, 's2');
      expect(output.spots[3].isTheoryNote, isTrue);
      expect(output.spots[3].note, 'In this section, we cover [bb] situations...');
      expect(output.spots[4].id, 's3');
    });
  });
}
