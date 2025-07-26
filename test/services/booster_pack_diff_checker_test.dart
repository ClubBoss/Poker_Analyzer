import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_pack_diff_checker.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/v2/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('diff detects added, removed and modified spots', () {
    final handA = HandData(
      heroCards: 'AhKh',
      position: HeroPosition.button,
      actions: {0: [ActionEntry(0, 0, 'push', ev: 1)]},
    );
    final handB = HandData(
      heroCards: 'AsKs',
      position: HeroPosition.smallBlind,
      actions: {0: [ActionEntry(0, 0, 'call', ev: 2)]},
    );
    final oldPack = TrainingPackTemplateV2(
      id: 'p',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      gameType: GameType.tournament,
      spots: [
        TrainingPackSpot(id: 's1', hand: handA, note: 'A'),
        TrainingPackSpot(id: 's2', hand: handA),
      ],
      spotCount: 2,
      created: DateTime.now(),
      positions: const [],
      meta: const {'type': 'booster'},
    );
    final newPack = TrainingPackTemplateV2(
      id: 'p',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      gameType: GameType.tournament,
      spots: [
        TrainingPackSpot(id: 's3', hand: handA),
        TrainingPackSpot(id: 's1', hand: handB, note: 'B'),
      ],
      spotCount: 2,
      created: DateTime.now(),
      positions: const [],
      meta: const {'type': 'booster'},
    );

    final report = const BoosterPackDiffChecker().diff(oldPack, newPack);

    expect(report.added, ['s3']);
    expect(report.removed, ['s2']);
    expect(report.breaking, isTrue);
    final mod = report.modified.firstWhere((d) => d.id == 's1');
    expect(mod.fields, contains('heroCards'));
    expect(mod.fields, contains('heroPosition'));
    expect(mod.fields, contains('actions'));
    expect(mod.fields, contains('order'));
    expect(mod.fields, contains('comment'));
    expect(mod.fields, contains('ev'));
  });
});
