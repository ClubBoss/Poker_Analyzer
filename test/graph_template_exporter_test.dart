import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/graph_template_exporter.dart';
import 'package:poker_analyzer/services/graph_path_template_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('encodeNodes serializes theory nodes', () async {
    const yaml = '''
nodes:
  - type: theory
    id: t1
    title: Intro
    content: Welcome
    next: [s1]
  - type: stage
    id: s1
''';
    final parser = GraphPathTemplateParser();
    final nodes = await parser.parseFromYaml(yaml);
    final exporter = GraphTemplateExporter(parser: parser);
    final out = exporter.encodeNodes(nodes);
    expect(out.contains('type: theory'), isTrue);
    expect(out.contains('Intro'), isTrue);
    expect(out.contains('s1'), isTrue);
  });
}
