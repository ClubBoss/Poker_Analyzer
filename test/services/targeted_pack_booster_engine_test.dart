import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TrainingPackTemplateV2 buildPack() {
    final spot1 = TrainingPackSpot(id: 's1', tags: ['push']);
    final spot2 = TrainingPackSpot(id: 's2', tags: ['fold']);
    return TrainingPackTemplateV2(
      id: 'p1',
      name: 'Sample',
      trainingType: TrainingType.custom,
      spots: [spot1, spot2],
      spotCount: 2,
      tags: const ['push', 'fold'],
      gameType: GameType.cash,
    );
  }

  test('generates booster for weak tag', () async {
    final engine = TargetedPackBoosterEngine(
      packsProvider: () => [buildPack()],
      cooldown: Duration.zero,
    );
    final boosters = await engine.generateBoostersFor(['push']);
    expect(boosters.length, 1);
    final b = boosters.first;
    expect(b.title, 'Booster — push');
    expect(b.tags, contains('push'));
    expect(b.metadata['booster'], true);
    expect(b.spots.length, 1);
    expect(b.spots.first.id, 's1');
  });

  test('enforces cooldown per tag', () async {
    final engine = TargetedPackBoosterEngine(
      packsProvider: () => [buildPack()],
    );
    final first = await engine.generateBoostersFor(['fold']);
    expect(first.length, 1);
    final second = await engine.generateBoostersFor(['fold']);
    expect(second, isEmpty);
  });

  test('deduplicates repeated tags', () async {
    final engine = TargetedPackBoosterEngine(
      packsProvider: () => [buildPack()],
      cooldown: Duration.zero,
    );
    final boosters =
        await engine.generateBoostersFor(['push', 'Push', ' push ']);
    expect(boosters.length, 1);
  });
}
