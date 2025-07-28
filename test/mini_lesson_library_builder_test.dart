import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mini_lesson_library_builder.dart';
import 'package:yaml/yaml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildYaml returns unique lessons with priority', () {
    final builder = MiniLessonLibraryBuilder();
    final entries = [
      const MiniLessonEntry(tag: 'tag1', title: 'A', content: 'c1'),
      const MiniLessonEntry(tag: 'tag1', title: 'A', content: 'dup'),
      const MiniLessonEntry(tag: 'tag2', title: 'B', content: 'c2'),
    ];
    final yaml = builder.buildYaml(entries, autoPriority: true);
    final map = loadYaml(yaml) as YamlMap;
    final list = map['lessons'] as YamlList;
    expect(list.length, 2);
    expect(list.first['priority'], 1);
    expect(list[1]['priority'], 2);
  });
});
