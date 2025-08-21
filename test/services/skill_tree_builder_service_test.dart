import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(
    String id, {
    List<String>? prereqs,
    String category = 'Push/Fold',
  }) =>
      SkillTreeNodeModel(
        id: id,
        title: id,
        category: category,
        prerequisites: prereqs,
      );

  test('builds tree with roots, children and ancestors', () {
    final nodes = [
      node('n1'),
      node('n2', prereqs: ['n1']),
      node('n3', prereqs: ['n1']),
      node('n4', prereqs: ['n2', 'n3']),
    ];
    final res = builder.build(nodes);
    expect(res.tree.roots.map((n) => n.id), ['n1']);
    expect(res.tree.childrenOf('n1').map((n) => n.id).toSet(), {'n2', 'n3'});
    expect(res.tree.ancestorsOf('n4').toSet().map((n) => n.id), {
      'n2',
      'n3',
      'n1',
    });
    expect(res.warnings, isEmpty);
  });

  test('filters by category', () {
    final nodes = [
      node('a', category: 'Push/Fold'),
      node('b', prereqs: ['a'], category: 'Push/Fold'),
      node('c', prereqs: ['b'], category: 'Postflop'),
    ];
    final res = builder.build(nodes, category: 'Push/Fold');
    expect(res.tree.roots.map((n) => n.id), ['a']);
    expect(res.tree.childrenOf('a').map((n) => n.id), ['b']);
    expect(res.tree.nodes.containsKey('c'), isFalse);
  });

  test('warns about circular dependencies', () {
    final nodes = [
      node('a', prereqs: ['b']),
      node('b', prereqs: ['a']),
    ];
    final res = builder.build(nodes);
    expect(res.warnings, isNotEmpty);
  });
}
