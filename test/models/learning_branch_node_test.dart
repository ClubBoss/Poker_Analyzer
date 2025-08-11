import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_branch_node.dart';

void main() {
  test('targetFor returns mapped node id', () {
    const node = LearningBranchNode(
      id: 'b1',
      prompt: 'Choose',
      branches: {'Cash': 'cash_intro', 'MTT': 'mtt_intro'},
    );
    expect(node.targetFor('Cash'), 'cash_intro');
    expect(node.targetFor('MTT'), 'mtt_intro');
    expect(node.targetFor('Other'), isNull);
  });

  test('fromJson parses branches', () {
    final json = {
      'id': 'b2',
      'prompt': 'Format?',
      'branches': {'A': 'n1', 'B': 'n2'}
    };
    final node = LearningBranchNode.fromJson(json);
    expect(node.id, 'b2');
    expect(node.prompt, 'Format?');
    expect(node.branches['A'], 'n1');
    expect(node.branches['B'], 'n2');
  });

  test('toJson outputs branches', () {
    const node = LearningBranchNode(
      id: 'b3',
      prompt: 'Example',
      branches: {'X': 'x1'},
    );
    final map = node.toJson();
    expect(map['id'], 'b3');
    expect(map['prompt'], 'Example');
    expect((map['branches'] as Map)['X'], 'x1');
  });

  test('fromYaml matches toJson round-trip', () {
    const yamlMap = {
      'id': 'b4',
      'prompt': 'Way?',
      'branches': {'Live': 'nLive', 'Online': 'nOnline'}
    };
    final node = LearningBranchNode.fromYaml(yamlMap);
    expect(node.toJson(), yamlMap);
  });
}
