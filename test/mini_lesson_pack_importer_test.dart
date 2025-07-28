import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mini_lesson_pack_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const basicYaml = '''
pack_id: mini_lessons_test
title: Test Pack
type: theory
lessons:
  - id: m1
    title: A
    content: c1
    tags: [t1]
  - id: m2
    title: B
    content: c2
    tags: [t2]
''';

  test('importFromYaml parses pack and lessons', () {
    final importer = MiniLessonPackImporter();
    final pack = importer.importFromYaml(basicYaml);
    expect(pack, isNotNull);
    expect(pack!.packId, 'mini_lessons_test');
    expect(pack.lessons.length, 2);
    expect(pack.lessons.first.id, 'm1');
  });

  const dupYaml = '''
pack_id: dup_pack
title: Dup Pack
type: theory
lessons:
  - id: m1
    title: A
    content: c1
  - id: m1
    title: B
    content: c2
''';

  test('importFromYaml skips duplicate ids', () {
    final importer = MiniLessonPackImporter();
    final pack = importer.importFromYaml(dupYaml);
    expect(pack, isNotNull);
    expect(pack!.lessons.length, 1);
  });
}
