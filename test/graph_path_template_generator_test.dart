import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/graph_path_template_generator.dart';
import 'package:poker_analyzer/services/graph_path_template_parser.dart';
import 'package:poker_analyzer/services/graph_path_template_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cash vs mtt template is valid', () async {
    const generator = GraphPathTemplateGenerator();
    final yaml = generator.generateCashVsMttTemplate();
    final nodes = await GraphPathTemplateParser().parseFromYaml(yaml);
    final issues = const GraphPathTemplateValidator().validate(nodes);
    expect(issues, isEmpty);
  });

  test('live vs online template is valid', () async {
    const generator = GraphPathTemplateGenerator();
    final yaml = generator.generateLiveVsOnlineTemplate();
    final nodes = await GraphPathTemplateParser().parseFromYaml(yaml);
    final issues = const GraphPathTemplateValidator().validate(nodes);
    expect(issues, isEmpty);
  });
}
