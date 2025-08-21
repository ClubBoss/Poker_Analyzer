import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_final_node_completion_detector.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';

class OptionalNode extends SkillTreeNodeModel {
  final bool isOptional;
  const OptionalNode({required String id, List<String>? prerequisites})
      : isOptional = true,
        super(
          id: id,
          title: id,
          category: 'Push/Fold',
          prerequisites: prerequisites,
        );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();
  final detector = SkillTreeFinalNodeCompletionDetector();

  SkillTreeNodeModel node(String id, {List<String>? prereqs}) =>
      SkillTreeNodeModel(
        id: id,
        title: id,
        category: 'Push/Fold',
        prerequisites: prereqs,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tree completed after all required nodes done', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    final tree = builder.build([
      node('n1'),
      node('n2', prereqs: ['n1']),
      OptionalNode(id: 'opt', prerequisites: ['n2']),
    ]).tree;

    expect(await detector.isTreeCompleted(tree), isFalse);

    await tracker.markCompleted('n1');
    expect(await detector.isTreeCompleted(tree), isFalse);

    await tracker.markCompleted('n2');
    expect(await detector.isTreeCompleted(tree), isTrue);

    await tracker.markCompleted('opt');
    expect(await detector.isTreeCompleted(tree), isTrue);
  });
}
