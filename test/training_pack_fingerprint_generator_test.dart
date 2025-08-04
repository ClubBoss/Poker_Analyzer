import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_fingerprint_generator.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  final gen = TrainingPackFingerprintGenerator();

  TrainingPackTemplateV2 buildPack(List<String> spotIds, {List<String>? tags}) {
    return TrainingPackTemplateV2(
      id: 'p1',
      name: 'Test',
      trainingType: TrainingType.quiz,
      tags: tags,
      spots: [
        for (final id in spotIds) TrainingPackSpot(id: id, hand: HandData()),
      ],
      spotCount: spotIds.length,
    );
  }

  test('fingerprint is deterministic regardless of ordering', () {
    final a = buildPack(['s1', 's2'], tags: ['b', 'a']);
    final b = buildPack(['s2', 's1'], tags: ['a', 'b']);
    expect(gen.generate(a), gen.generate(b));
  });

  test('different packs produce different fingerprints', () {
    final a = buildPack(['s1', 's2']);
    final b = buildPack(['s1', 's3']);
    expect(gen.generate(a), isNot(gen.generate(b)));
  });
}
