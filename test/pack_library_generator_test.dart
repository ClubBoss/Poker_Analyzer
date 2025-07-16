import 'package:test/test.dart';
import 'package:poker_analyzer/core/training/generation/pack_library_generator.dart';
import 'package:poker_analyzer/services/hand_range_library.dart';

void main() {
  test('generateFromYaml returns templates', () {
    const yaml = '''
packs:
  - gameType: tournament
    bb: 10
    positions: [sb]
    title: Example
    description: Test
    tags: [pushfold]
    count: 5
''';
    final generator = PackLibraryGenerator();
    final list = generator.generateFromYaml(yaml);
    expect(list.length, 1);
    final tpl = list.first;
    expect(tpl.name, 'Example');
    expect(tpl.description, 'Test');
    expect(tpl.tags.contains('pushfold'), true);
    expect(tpl.spots.length, 5);
    expect(tpl.spotCount, tpl.spots.length);
    expect(tpl.id.isNotEmpty, true);
  });

  test('generateFromYaml handles bbList', () {
    const yaml = '''
packs:
  - gameType: tournament
    bbList: [10, 15]
    positions: [sb]
    count: 2
''';
    final generator = PackLibraryGenerator();
    final list = generator.generateFromYaml(yaml);
    expect(list.first.spots.length, 4);
    expect(list.first.spotCount, 4);
  });

  test('generateFromYaml uses rangeGroup', () {
    const yaml = '''
packs:
  - gameType: tournament
    bb: 10
    positions: [sb]
    rangeGroup: top10
''';
    final generator = PackLibraryGenerator();
    final list = generator.generateFromYaml(yaml);
    expect(list.first.spots.length, HandRangeLibrary.getGroup('top10').length);
  });

  test('generateFromYaml adds range tag', () {
    const yaml = '''
defaultRangeTags: true
packs:
  - gameType: tournament
    bb: 10
    positions: [sb]
    rangeGroup: top10
''';
    final generator = PackLibraryGenerator();
    final list = generator.generateFromYaml(yaml);
    expect(list.first.tags.contains('top10'), true);
  });

  test('generateFromYaml generates default title', () {
    const yaml = '''
packs:
  - gameType: tournament
    bb: 10
    positions: [sb]
''';
    final generator = PackLibraryGenerator();
    final list = generator.generateFromYaml(yaml);
    expect(list.first.name, 'SB Push 10bb (Tournament)');
  });

  test('generateFromYaml generates description when empty', () {
    const yaml = '''
packs:
  - gameType: tournament
    bb: 10
    positions: [sb]
''';
    final generator = PackLibraryGenerator();
    final list = generator.generateFromYaml(yaml);
    expect(list.first.description.isNotEmpty, true);
  });
}
