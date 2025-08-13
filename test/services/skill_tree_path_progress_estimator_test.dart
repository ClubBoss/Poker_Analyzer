import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_path_progress_estimator.dart';
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
  SkillTreeBuildResult? getTrack(String trackId) => _trees[trackId];

  @override
  List<SkillTreeBuildResult> getAllTracks() => List.unmodifiable(_trees.values);

  @override
  List<SkillTreeNodeModel> getAllNodes() => List.unmodifiable(_nodes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id, {List<String>? prereqs}) =>
      SkillTreeNodeModel(
        id: id,
        title: id,
        category: 'T',
        prerequisites: prereqs,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('computes percent based on unlocked nodes', () async {
    final nodes = [
      node('a'),
      node('b', prereqs: ['a']),
      node('c', prereqs: ['b']),
    ];
    final tree = builder.build(nodes, category: 'T');
    final lib = _FakeLibraryService({'T': tree}, nodes);

    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    final estimator = SkillTreePathProgressEstimator(
      library: lib,
      progress: tracker,
    );

    expect(await estimator.getProgressPercent('T'), 0);

    await tracker.markCompleted('a');
    expect(await estimator.getProgressPercent('T'), 50);

    await tracker.markCompleted('b');
    expect(await estimator.getProgressPercent('T'), 67);
  });
}
