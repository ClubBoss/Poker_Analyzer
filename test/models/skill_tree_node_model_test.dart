import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';

void main() {
  test('json round-trip', () {
    const node = SkillTreeNodeModel(
      id: 'n1',
      title: 'Push/Fold EP',
      category: 'Push/Fold',
      trainingPackId: 'pack1',
      theoryLessonId: 'lesson1',
    );
    final map = node.toJson();
    final from = SkillTreeNodeModel.fromJson(map);
    expect(from.id, 'n1');
    expect(from.title, 'Push/Fold EP');
    expect(from.category, 'Push/Fold');
    expect(from.trainingPackId, 'pack1');
    expect(from.theoryLessonId, 'lesson1');
  });

  test('fromYaml matches toJson round-trip', () {
    const yamlMap = {
      'id': 'n2',
      'title': '3-Bet Jam',
      'category': 'Push/Fold',
      'trainingPackId': 'pack2',
      'theoryLessonId': 'lesson2',
      'level': 1,
      'prerequisites': ['n1'],
      'unlockedNodeIds': ['n3'],
    };
    final node = SkillTreeNodeModel.fromYaml(yamlMap);
    expect(node.toJson(), yamlMap);
  });
}
