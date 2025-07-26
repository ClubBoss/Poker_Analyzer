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
}
