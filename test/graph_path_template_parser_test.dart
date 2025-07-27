import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/graph_path_template_parser.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';
import 'package:poker_analyzer/models/learning_branch_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parseFromYaml builds nodes', () async {
    const yaml = '''
nodes:
  - type: branch
    id: start
    prompt: Choose format
    branches:
      Cash: cash_intro
      MTT: mtt_intro

  - type: stage
    id: cash_intro
    stageId: cash_welcome
    next: [mtt_intro]

  - type: stage
    id: mtt_intro
    stageId: mtt_welcome
''';
    final parser = GraphPathTemplateParser();
    final nodes = await parser.parseFromYaml(yaml);
    expect(nodes.length, 3);
    expect(nodes.first, isA<LearningBranchNode>());
    final branch = nodes.first as LearningBranchNode;
    expect(branch.branches['Cash'], 'cash_intro');
    final stage = nodes[1] as StageNode;
    expect(stage.nextIds, ['mtt_intro']);
  });
}
