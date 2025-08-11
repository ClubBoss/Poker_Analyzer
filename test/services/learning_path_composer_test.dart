import 'package:test/test.dart';

import 'package:poker_analyzer/services/learning_path_composer.dart';

void main() {
  group('LearningPathComposer', () {
    test('difficulty scoring', () {
      const meta = PackMeta(
        id: 'p1',
        categories: ['a'],
        textureDistribution: {'monotone': 0.1, 'two': 0.4, 'rainbow': 0.5},
        avgTheoryScore: 0.8,
        presetId: 'x',
        streets: 3,
        tagComplexity: 0.5,
        noveltyScore: 0.2,
      );
      final score = const DifficultyScorer().score(meta);
      expect(score, closeTo(0.541, 0.001));
    });

    test('quota satisfaction', () {
      const packs = [
        PackMeta(
          id: 'a',
          categories: ['c1'],
          textureDistribution: {'monotone': 0.05},
          avgTheoryScore: 0.8,
          presetId: 'x',
          tagComplexity: 0.3,
          noveltyScore: 0.1,
        ),
        PackMeta(
          id: 'b',
          categories: ['c2'],
          textureDistribution: {'monotone': 0.05},
          avgTheoryScore: 0.8,
          presetId: 'x',
          tagComplexity: 0.3,
          noveltyScore: 0.1,
        ),
        PackMeta(
          id: 'c',
          categories: ['c3'],
          textureDistribution: {'monotone': 0.05},
          avgTheoryScore: 0.8,
          presetId: 'x',
          tagComplexity: 0.3,
          noveltyScore: 0.1,
        ),
      ];
      final result = LearningPathComposer().compose(packs);
      final level1 = result.assignments[1] ?? const [];
      final covered = level1.expand((p) => p.categories).toSet();
      expect(covered.length, greaterThanOrEqualTo(3));
    });

    test('deterministic selection', () {
      const packs = [
        PackMeta(
          id: 'a',
          categories: ['c1'],
          textureDistribution: const {},
          avgTheoryScore: 0.8,
          presetId: 'x',
          tagComplexity: 0.3,
          noveltyScore: 0.1,
        ),
        PackMeta(
          id: 'b',
          categories: ['c2'],
          textureDistribution: const {},
          avgTheoryScore: 0.8,
          presetId: 'x',
          tagComplexity: 0.3,
          noveltyScore: 0.1,
        ),
      ];
      final r1 = LearningPathComposer().compose(packs);
      final r2 = LearningPathComposer().compose(packs.reversed.toList());
      expect(
        r1.path.stages.map((s) => s.packId).toList(),
        r2.path.stages.map((s) => s.packId).toList(),
      );
    });
  });
}
