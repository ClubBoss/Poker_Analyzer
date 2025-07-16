import 'package:test/test.dart';
import 'package:poker_analyzer/core/training/generation/pack_library_generator.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/core/training/generation/training_pack_generator_engine.dart';

class FakeEngine extends TrainingPackGeneratorEngine {
  const FakeEngine();
  @override
  Future<TrainingPackV2> generateFromTemplate(TrainingPackTemplateV2 template) async {
    final spots = [for (final s in template.spots) TrainingPackSpot.fromJson(s.toJson())];
    return TrainingPackV2(
      id: template.id,
      sourceTemplateId: template.id,
      name: template.name,
      description: template.description,
      tags: List<String>.from(template.tags),
      type: template.type,
      spots: spots,
      spotCount: spots.length,
      generatedAt: DateTime.now(),
      gameType: template.gameType,
      bb: template.bb,
      positions: List<String>.from(template.positions),
      difficulty: template.meta['difficulty'] is int ? template.meta['difficulty'] as int : spots.length,
      meta: Map<String, dynamic>.from(template.meta),
    );
  }
}

void main() {
  test('generateFromTemplates skips disabled and empty', () async {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10),
    );
    final enabled = TrainingPackTemplateV2(
      id: '1',
      name: 'A',
      type: TrainingType.pushfold,
      spots: [spot],
    );
    final disabled = TrainingPackTemplateV2(
      id: '2',
      name: 'B',
      type: TrainingType.pushfold,
      meta: {'enabled': false},
      spots: [spot],
    );
    final empty = TrainingPackTemplateV2(
      id: '3',
      name: 'C',
      type: TrainingType.pushfold,
    );
    final generator = PackLibraryGenerator(packEngine: const FakeEngine());
    final res = await generator.generateFromTemplates([enabled, disabled, empty]);
    expect(res.length, 1);
    expect(res.first.sourceTemplateId, '1');
  });

  test('generateFromTemplates sorts by priority', () async {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10),
    );
    final high = TrainingPackTemplateV2(
      id: '1',
      name: 'High',
      type: TrainingType.pushfold,
      meta: {'priority': 2},
      spots: [spot],
    );
    final low = TrainingPackTemplateV2(
      id: '2',
      name: 'Low',
      type: TrainingType.pushfold,
      meta: {'priority': 1},
      spots: [spot],
    );
    final generator = PackLibraryGenerator(packEngine: const FakeEngine());
    final res = await generator.generateFromTemplates([high, low]);
    expect(res.first.sourceTemplateId, '2');
    expect(res.last.sourceTemplateId, '1');
  });
}
