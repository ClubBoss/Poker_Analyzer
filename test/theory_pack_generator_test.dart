import 'package:test/test.dart';
import 'package:poker_analyzer/services/theory_pack_generator.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  const generator = TheoryPackGenerator();

  test('generate returns valid template', () {
    final tpl = generator.generate('push_sb', 'test');
    expect(tpl.id, 'test_push_sb_theory');
    expect(tpl.trainingType, TrainingType.theory);
    expect(tpl.tags, contains('push_sb'));
    expect(tpl.spots.length, 1);
    expect(tpl.meta['schemaVersion'], '2.0.0');
  });

  test('uses booster description when available', () {
    final tpl = generator.generate('push_sb', 'demo');
    expect(tpl.spots.first.explanation?.isNotEmpty, true);
  });

  test('uses default text when none provided', () {
    final tpl = generator.generate('unknown', 'demo');
    final spot = tpl.spots.first;
    expect(spot.title, TheoryPackGenerator.defaultQuestion);
    expect(spot.note, TheoryPackGenerator.defaultSolution);
    expect(spot.explanation, TheoryPackGenerator.defaultExplanation);
  });

  test('allows localized overrides', () {
    const q = 'Вопрос';
    const s = 'Ответ';
    const e = 'Объяснение';
    final tpl = generator.generate(
      'push_sb',
      'loc',
      question: q,
      solution: s,
      explanation: e,
    );
    final spot = tpl.spots.first;
    expect(spot.title, q);
    expect(spot.note, s);
    expect(spot.explanation, e);
  });
}
