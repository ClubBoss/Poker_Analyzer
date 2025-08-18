import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/graph_path_template_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const badYaml = '''
nodes:
  - type: stage
    id: start
    next: [a]
  - type: stage
    id: a
    next: [missing]
  - type: branch
    id: b
    branches:
      A: a
      B: orphan
  - type: stage
    id: loop
    next: [loop]
  - type: stage
    id: unreachable
''';

  const goodYaml = '''
nodes:
  - type: stage
    id: start
    next: [end]
  - type: stage
    id: end
''';

  test('validator detects structural issues', () async {
    final issues = await const GraphPathTemplateValidator().validateYaml(
      badYaml,
    );
    final messages = issues.map((e) => e.message).toList();
    expect(messages, contains('unknown_next:a:missing'));
    expect(messages, contains('unknown_target:b:orphan'));
    expect(messages, contains('cycle:loop'));
    expect(messages, contains('orphan:unreachable'));
  });

  test('validator passes for valid path', () async {
    final issues = await const GraphPathTemplateValidator().validateYaml(
      goodYaml,
    );
    expect(issues, isEmpty);
  });

  test('validator accepts theory nodes', () async {
    const yaml = '''
nodes:
  - type: theory
    id: t1
    title: Intro
    content: Text
    next: [end]
  - type: stage
    id: end
''';
    final issues = await const GraphPathTemplateValidator().validateYaml(yaml);
    expect(issues, isEmpty);
  });
}
