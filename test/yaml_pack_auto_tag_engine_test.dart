import 'package:test/test.dart';
import 'package:poker_analyzer/services/yaml_pack_auto_tag_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TrainingPackSpot spot({
    required HeroPosition pos,
    required double stack,
    List<String> heroOpts = const ['push'],
  }) {
    return TrainingPackSpot(
      id: 's${pos.name}-$stack',
      hand: HandData(
        position: pos,
        heroIndex: 0,
        stacks: {'0': stack},
        actions: {
          0: [ActionEntry(0, 0, heroOpts.first)],
        },
      ),
      heroOptions: heroOpts,
    );
  }

  test('detects pushfold and hero position', () {
    final tpl = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Test',
      trainingType: TrainingType.pushFold,
      gameType: GameType.tournament,
      spots: [
        spot(pos: HeroPosition.btn, stack: 10),
        spot(pos: HeroPosition.btn, stack: 12),
      ],
    );
    final tags = const YamlPackAutoTagEngine().autoTag(tpl);
    expect(tags, contains('pushfold'));
    expect(tags, contains('heroBTN'));
  });

  test('detects icm and cash', () {
    final tpl = TrainingPackTemplateV2(
      id: 'p2',
      name: 'Test',
      meta: {'icm': true},
      gameType: GameType.cash,
      trainingType: TrainingType.pushFold,
    );
    final tags = const YamlPackAutoTagEngine().autoTag(tpl);
    expect(tags, contains('icm'));
    expect(tags, contains('cash'));
  });

  test('detects 3bet action', () {
    final tpl = TrainingPackTemplateV2(
      id: 'p3',
      name: 'T',
      trainingType: TrainingType.pushFold,
      spots: [
        spot(pos: HeroPosition.sb, stack: 20, heroOpts: ['3betPush', 'fold']),
      ],
    );
    final tags = const YamlPackAutoTagEngine().autoTag(tpl);
    expect(tags, contains('3bet'));
  });
}
