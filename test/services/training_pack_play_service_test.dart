import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/training_pack_variant.dart';
import 'package:poker_analyzer/services/training_pack_play_service.dart';

void main() {
  test('loadSpots caches result and reloads on force', () async {
    final tpl = TrainingPackTemplate(
      id: 't',
      name: 'Test',
      heroBbStack: 10,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      spotCount: 2,
      heroRange: const ['AA', 'KK'],
    );
    const variant = TrainingPackVariant(
      position: HeroPosition.sb,
      gameType: GameType.tournament,
    );
    final service = TrainingPackPlayService();
    final list1 = await service.loadSpots(tpl, variant);
    final list2 = await service.loadSpots(tpl, variant);
    expect(identical(list1, list2), isTrue);
    final list3 = await service.loadSpots(tpl, variant, forceReload: true);
    expect(identical(list2, list3), isFalse);
  });
}
