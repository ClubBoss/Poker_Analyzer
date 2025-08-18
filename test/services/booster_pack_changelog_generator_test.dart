import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_pack_changelog_generator.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/v2/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrainingPackTemplateV2 pack(List<TrainingPackSpot> spots, List<String> tags) {
    return TrainingPackTemplateV2(
      id: 'p',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      gameType: GameType.tournament,
      spots: spots,
      spotCount: spots.length,
      tags: tags,
      created: DateTime.now(),
      positions: const [],
      meta: const {'type': 'booster'},
    );
  }

  test('buildChangelog lists spot and tag changes', () {
    final spotA = TrainingPackSpot(
      id: 's1',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.button,
        actions: {
          0: [ActionEntry(0, 0, 'push', ev: 1)],
        },
      ),
      explanation: 'A',
    );
    final oldPack = pack([spotA], ['btnPush']);

    final spotB = TrainingPackSpot(
      id: 's1',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.smallBlind,
        actions: {
          0: [ActionEntry(0, 0, 'push', ev: 2)],
        },
      ),
      explanation: 'B',
    );
    final spotC = TrainingPackSpot(id: 's2', hand: HandData());
    final newPack = pack([spotB, spotC], ['btnPush', 'new']);

    final md = const BoosterPackChangelogGenerator().buildChangelog(
      oldPack,
      newPack,
    );

    expect(md, contains('Spots')); // spot count change
    expect(md, contains('New tags')); // new tag
    expect(md, contains('Added spots')); // added spot
    expect(md, contains('s1:')); // modified spot
  });
}
