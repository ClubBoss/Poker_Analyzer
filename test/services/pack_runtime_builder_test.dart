import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_runtime_builder.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/training_pack_variant.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/game_type.dart';

void main() {
  test('buildIfNeeded returns cached list', () async {
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
    final builder = PackRuntimeBuilder();
    final list1 = await builder.buildIfNeeded(tpl, variant);
    await Future.delayed(Duration.zero);
    final list2 = await builder.buildIfNeeded(tpl, variant);
    expect(identical(list1, list2), isTrue);
  });
}
