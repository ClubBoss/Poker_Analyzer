import 'package:test/test.dart';
import 'package:poker_analyzer/core/training/generation/pack_library_generator.dart';

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
    expect(tpl.tags, ['pushfold']);
    expect(tpl.spots.length, 5);
    expect(tpl.spotCount, tpl.spots.length);
    expect(tpl.id.isNotEmpty, true);
  });
}
