import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_final_node_completion_detector.dart';
import 'package:poker_analyzer/services/skill_tree_track_progress_service.dart';
import 'package:poker_analyzer/services/skill_tree_library_service.dart';

class _FakeLibraryService implements SkillTreeLibraryService {
  final Map<String, SkillTreeBuildResult> _trees;
  final List<SkillTreeNodeModel> _nodes;
  _FakeLibraryService(this._trees, this._nodes);

  @override
  Future<void> reload() async {}

  @override
  SkillTreeBuildResult? getTree(String category) => _trees[category];

  @override
  List<SkillTreeNodeModel> getAllNodes() => List.unmodifiable(_nodes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id, String cat, {List<String>? prereqs}) =>
      SkillTreeNodeModel(
        id: id,
        title: id,
        category: cat,
        prerequisites: prereqs,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('computes progress for all tracks', () async {
    final nodesA = [
      node('a1', 'A'),
      node('a2', 'A', prereqs: ['a1']),
    ];
    final nodesB = [
      node('b1', 'B'),
      node('b2', 'B', prereqs: ['b1']),
    ];
    final treeA = builder.build(nodesA).tree;
    final treeB = builder.build(nodesB).tree;
    final lib = _FakeLibraryService(
      {
        'A': SkillTreeBuildResult(tree: treeA),
        'B': SkillTreeBuildResult(tree: treeB),
      },
      [...nodesA, ...nodesB],
    );

    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    await tracker.markCompleted('a1');

    final svc = SkillTreeTrackProgressService(
      library: lib,
      progress: tracker,
      detector: SkillTreeFinalNodeCompletionDetector(progress: tracker),
    );

    final all = await svc.getAllTrackProgress();
    expect(all.length, 2);
    expect(all.first.tree.nodes.containsKey('a1'), isTrue);
    expect(all.first.completionRate, closeTo(0.5, 1e-6));
    expect(all.first.isCompleted, isFalse);
  });

  test('current and next track', () async {
    final nodesA = [
      node('a1', 'A'),
      node('a2', 'A', prereqs: ['a1']),
    ];
    final nodesB = [node('b1', 'B')];
    final treeA = builder.build(nodesA).tree;
    final treeB = builder.build(nodesB).tree;
    final lib = _FakeLibraryService(
      {
        'A': SkillTreeBuildResult(tree: treeA),
        'B': SkillTreeBuildResult(tree: treeB),
      },
      [...nodesA, ...nodesB],
    );

    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    final svc = SkillTreeTrackProgressService(
      library: lib,
      progress: tracker,
      detector: SkillTreeFinalNodeCompletionDetector(progress: tracker),
    );

    var current = await svc.getCurrentTrack();
    var next = await svc.getNextTrack();
    expect(current?.tree.nodes.containsKey('a1'), isTrue);
    expect(next?.tree.nodes.containsKey('b1'), isTrue);

    await tracker.markCompleted('a1');
    await tracker.markCompleted('a2');

    current = await svc.getCurrentTrack();
    next = await svc.getNextTrack();
    expect(current?.tree.nodes.containsKey('b1'), isTrue);
    expect(next, isNull);
  });
}
