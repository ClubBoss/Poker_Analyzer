import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_track_engine.dart';
import 'package:poker_analyzer/services/training_pack_stats_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/unlock_rules.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackTemplateV2 tpl(String id, {UnlockRules? rules}) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    trainingType: TrainingType.pushFold,
    unlockRules: rules,
    spots: const [],
    spotCount: 0,
  );
}

TrainingPackStat stat(double accuracy) => TrainingPackStat(
      accuracy: accuracy,
      last: DateTime.now(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computeTrack returns unlocked packs and next up', () {
    final packs = [
      tpl('a'),
      tpl('b', rules: const UnlockRules(requiredPacks: ['a'])),
      tpl('c'),
    ];
    final stats = {
      'a': stat(1.0),
      'b': stat(0.95),
      'c': stat(0.8),
    };

    final track =
        const LearningTrackEngine().computeTrack(allPacks: packs, stats: stats);

    expect(track.unlockedPacks.map((p) => p.id), ['a', 'b', 'c']);
    expect(track.nextUpPack?.id, 'c');
  });

  test('nextUpPack null when all completed', () {
    final packs = [tpl('a'), tpl('b')];
    final stats = {'a': stat(0.95), 'b': stat(0.92)};

    final track =
        const LearningTrackEngine().computeTrack(allPacks: packs, stats: stats);

    expect(track.unlockedPacks.length, 2);
    expect(track.nextUpPack, isNull);
  });
}
