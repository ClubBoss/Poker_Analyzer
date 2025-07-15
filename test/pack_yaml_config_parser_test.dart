import 'package:test/test.dart';
import 'package:poker_analyzer/core/training/generation/pack_yaml_config_parser.dart';
import 'package:poker_analyzer/core/training/generation/pack_generation_request.dart';
import 'package:poker_analyzer/models/game_type.dart';

void main() {
  test('parse returns requests', () {
    const yaml = '''
packs:
  - gameType: tournament
    bb: 10
    positions: [sb, bb]
    title: Test
    description: Desc
    tags: [pushfold]
  - gameType: cash
    bb: 50
    positions: [btn]
    title: Cash
    description: Example
    tags: [cash]
''';
    final parser = PackYamlConfigParser();
    final list = parser.parse(yaml);
    expect(list.length, 2);
    expect(list.first.gameType, GameType.tournament);
    expect(list.first.bb, 10);
    expect(list.first.positions, ['sb', 'bb']);
    expect(list.first.title, 'Test');
    expect(list.first.tags, ['pushfold']);
    expect(list.last.gameType, GameType.cash);
  });
}
