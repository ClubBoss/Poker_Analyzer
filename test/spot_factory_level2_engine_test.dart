import 'package:test/test.dart';
import 'package:poker_analyzer/core/training/factory/spot_factory_level2_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';

void main() {
  test('generate open spots', () {
    const engine = SpotFactoryLevel2Engine();
    final spots = engine.generate(
      gameType: GameType.tournament,
      isHeroFirstIn: true,
      include3betPush: false,
      count: 3,
    );
    expect(spots.length, 3);
    expect(spots.every((s) => s.tags.contains('open')), true);
    expect(spots.every((s) => s.note.isNotEmpty), true);
  });

  test('generate vs open with 3bet push', () {
    const engine = SpotFactoryLevel2Engine();
    final spots = engine.generate(
      gameType: GameType.cash,
      isHeroFirstIn: false,
      include3betPush: true,
      count: 2,
    );
    expect(spots.length, 2);
    expect(spots.every((s) => s.tags.contains('vsopen')), true);
    expect(spots.any((s) => s.tags.contains('3betpush')), true);
  });
}
