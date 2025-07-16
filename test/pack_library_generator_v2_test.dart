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
    final spot = TrainingPackSpot(id: 's1', hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10));
    final enabled = TrainingPackTemplateV2(id: '1', name: 'A', type: TrainingType.pushfold, spots: [spot]);
    final disabled = TrainingPackTemplateV2(
      id: '2',
      name: 'B',
      type: TrainingType.pushfold,
      meta: {'enabled': false},
      spots: [spot],
    );
    final empty = TrainingPackTemplateV2(id: '3', name: 'C', type: TrainingType.pushfold);
    final generator = PackLibraryGenerator(packEngine: const FakeEngine());
    final res = await generator.generateFromTemplates([enabled, disabled, empty]);
    expect(res.length, 1);
    expect(res.first.sourceTemplateId, '1');
  });

  test('generateFromTemplates sorts by priority', () async {
    final spot = TrainingPackSpot(id: 's1', hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10));
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

  test('estimateDifficulty sets meta', () async {
    final s1 = TrainingPackSpot(id: 's1', hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10));
    final s2 = TrainingPackSpot(
      id: 's2',
      hand: HandData.fromSimpleInput('KdQd', HeroPosition.bb, 20)..board.addAll(['2h', '3d', '4s']),
    );
    final s3 = TrainingPackSpot(
      id: 's3',
      hand: HandData.fromSimpleInput('JcJs', HeroPosition.btn, 15)..board.addAll(['2h', '3d', '4s', '5c']),
    );
    final tpl = TrainingPackTemplateV2(id: 't', name: 'T', type: TrainingType.pushfold, spots: [s1, s2, s3]);
    final generator = PackLibraryGenerator(packEngine: const FakeEngine());
    final res = await generator.generateFromTemplates([tpl]);
    expect(res.first.meta['difficulty'], 3);
  });

  test('generateFromTemplates adds auto tags', () async {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(
        position: HeroPosition.bb,
        heroIndex: 0,
        playerCount: 3,
        stacks: {'0': 20, '1': 20, '2': 20},
        board: ['2h', '3d', '4s', '5c'],
      ),
    );
    final tpl = TrainingPackTemplateV2(id: 'x', name: 'X', type: TrainingType.pushfold, spots: [spot]);
    final generator = PackLibraryGenerator(packEngine: const FakeEngine());
    final res = await generator.generateFromTemplates([tpl]);
    final tags = res.first.tags;
    expect(tags.contains('BB'), true);
    expect(tags.contains('3way'), true);
    expect(tags.contains('20bb'), true);
    expect(tags.contains('flop'), true);
    expect(tags.contains('turn'), true);
  });

  test('generateFromTemplates generates title when empty', () async {
    final spot = TrainingPackSpot(id: 's1', hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10));
    final tpl = TrainingPackTemplateV2(
      id: 'z',
      name: '',
      type: TrainingType.pushfold,
      gameType: GameType.tournament,
      bb: 10,
      positions: ['sb'],
      spots: [spot],
    );
    final generator = PackLibraryGenerator(packEngine: const FakeEngine());
    final res = await generator.generateFromTemplates([tpl]);
    expect(res.first.name, 'SB Push 10bb (Tournament)');
  });

  test('generateFromTemplates generates description when empty', () async {
    final spot = TrainingPackSpot(id: 's1', hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10));
    final tpl = TrainingPackTemplateV2(
      id: 'y',
      name: 'T',
      description: '',
      type: TrainingType.pushfold,
      gameType: GameType.tournament,
      bb: 10,
      positions: ['sb'],
      spots: [spot],
    );
    final generator = PackLibraryGenerator(packEngine: const FakeEngine());
    final res = await generator.generateFromTemplates([tpl]);
    expect(res.first.description.isNotEmpty, true);
  });
}
