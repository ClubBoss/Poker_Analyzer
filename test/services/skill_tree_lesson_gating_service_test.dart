import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_final_node_completion_detector.dart';
import 'package:poker_analyzer/services/skill_tree_library_service.dart';
import 'package:poker_analyzer/services/skill_tree_lesson_gating_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_track_progress_service.dart';

class _FakeLibraryService implements SkillTreeLibraryService {
  @override
  Future<void> reload() async {}

  @override
  SkillTreeBuildResult? getTree(String category) => null;

  @override
  List<SkillTreeNodeModel> getAllNodes() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

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

  test('computes visibility and enablement for nodes', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    final tree = builder.build([
      node('n1'),
      node('n2', prereqs: ['n1']),
      node('n3', prereqs: ['n1']),
      node('n4', prereqs: ['n2', 'n3']),
    ]).tree;

    final progressService = SkillTreeTrackProgressService(
      library: _FakeLibraryService(),
      progress: tracker,
      detector: SkillTreeFinalNodeCompletionDetector(progress: tracker),
    );
    final gating = SkillTreeLessonGatingService(
      progressService: progressService,
    );

    var map = await gating.evaluate(tree);
    expect(map['n1']!.isVisible, isTrue);
    expect(map['n1']!.isEnabled, isTrue);
    expect(map['n2']!.isVisible, isTrue);
    expect(map['n2']!.isEnabled, isFalse);
    expect(map['n4']!.isVisible, isTrue);
    expect(map['n4']!.isEnabled, isFalse);

    await tracker.markCompleted('n1');
    map = await gating.evaluate(tree);
    expect(map['n2']!.isEnabled, isTrue);
    expect(map['n3']!.isEnabled, isTrue);
    expect(map['n4']!.isEnabled, isFalse);

    await tracker.markCompleted('n2');
    await tracker.markCompleted('n3');
    map = await gating.evaluate(tree);
    expect(map['n4']!.isEnabled, isTrue);
  });
}
