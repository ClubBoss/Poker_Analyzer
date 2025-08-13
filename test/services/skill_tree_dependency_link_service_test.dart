import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_dependency_link_service.dart';
import 'package:poker_analyzer/services/skill_tree_graph_service.dart';
import 'package:poker_analyzer/services/skill_tree_library_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_detail_unlock_hint_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_track_resolver.dart';

class _FakeLibraryService implements SkillTreeLibraryService {
  final SkillTreeBuildResult result;
  _FakeLibraryService(this.result);

  @override
  Future<void> reload() async {}

  @override
  SkillTreeBuildResult? getTree(String category) => result;

  @override
  List<SkillTreeNodeModel> getAllNodes() => result.tree.nodes.values.toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id,
          {List<String>? prereqs, List<String>? unlocks, int level = 0}) =>
      SkillTreeNodeModel(
        id: id,
        title: id,
        category: 'Push/Fold',
        prerequisites: prereqs,
        unlockedNodeIds: unlocks,
        level: level,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns dependency links for locked chain', () async {
    final nodes = [
      node('n1', unlocks: ['n2']),
      node('n2', prereqs: ['n1'], unlocks: ['n3']),
      node('n3', prereqs: ['n2']),
    ];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService(SkillTreeBuildResult(tree: tree));
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    final resolver = SkillTreeTrackResolver(library: lib);
    final svc = SkillTreeDependencyLinkService(
      library: lib,
      graph: const SkillTreeGraphService(),
      hintService: const SkillTreeNodeDetailUnlockHintService(),
      progress: tracker,
      resolver: resolver,
    );
    final deps = await svc.getDependencies('n3');
    expect(deps.length, 2);
    expect(deps[0].nodeId, 'n3');
    expect(deps[0].prerequisites, ['n1', 'n2']);
    expect(deps[1].nodeId, 'n2');
    expect(deps[1].prerequisites, ['n1']);
  });

  test('returns empty list when node unlocked', () async {
    final nodes = [
      node('n1', unlocks: ['n2']),
      node('n2', prereqs: ['n1'], unlocks: ['n3']),
      node('n3', prereqs: ['n2']),
    ];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService(SkillTreeBuildResult(tree: tree));
    SkillTreeTrackResolver.instance = SkillTreeTrackResolver(library: lib);
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    await tracker.markCompleted('n1');
    await tracker.markCompleted('n2');
    final svc = SkillTreeDependencyLinkService(
      library: lib,
      graph: const SkillTreeGraphService(),
      hintService: const SkillTreeNodeDetailUnlockHintService(),
      progress: tracker,
      resolver: SkillTreeTrackResolver.instance,
    );
    final deps = await svc.getDependencies('n3');
    expect(deps, isEmpty);
  });
}
