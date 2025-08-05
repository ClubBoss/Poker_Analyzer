import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_library_generator.dart';
import 'package:poker_analyzer/models/training_pack_template_set_group.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

TrainingPackTemplateSet _validSet() {
  final spot = TrainingPackSpot(
    id: 's1',
    hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10),
  );
  return TrainingPackTemplateSet(baseSpot: spot);
}

void main() {
  group('TrainingPackLibraryGenerator', () {
    test('empty group list', () {
      final gen = TrainingPackLibraryGenerator();
      final res = gen.generate([]);
      expect(res, isEmpty);
      expect(gen.errors, isEmpty);
    });

    test('valid and invalid groups', () {
      final valid = TrainingPackTemplateSetGroup(
        packId: 'p1',
        title: 'Valid',
        sets: [_validSet()],
      );
      final invalidSpot = TrainingPackSpot(
        id: 's2',
        hand: HandData.fromSimpleInput('KdQc', HeroPosition.bb, 10),
      );
      final invalidSet = TrainingPackTemplateSet(
        baseSpot: invalidSpot,
        requiredBoardClusters: ['never'],
      );
      final invalid = TrainingPackTemplateSetGroup(
        packId: 'p2',
        title: 'Invalid',
        sets: [invalidSet],
      );
      final gen = TrainingPackLibraryGenerator();
      final res = gen.generate([valid, invalid]);
      expect(res.length, 1);
      expect(res.first.id, 'p1');
      expect(gen.errors.length, 1);
    });

    test('multi-pack generation', () {
      final g1 = TrainingPackTemplateSetGroup(
        packId: 'a',
        title: 'A',
        sets: [_validSet()],
      );
      final g2 = TrainingPackTemplateSetGroup(
        packId: 'b',
        title: 'B',
        sets: [_validSet()],
      );
      final gen = TrainingPackLibraryGenerator();
      final res = gen.generate([g1, g2]);
      expect(res.length, 2);
      expect(res.map((p) => p.id), containsAll(['a', 'b']));
    });
  });
}
