import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_lock_reason_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_stage_gate_evaluator.dart';
import 'package:poker_analyzer/services/skill_tree_unlock_evaluator.dart';
import 'package:poker_analyzer/services/skill_tree_library_service.dart';

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

  SkillTreeNodeModel node(String id, {List<String>? prereqs, int level = 0}) =>
      SkillTreeNodeModel(
          id: id,
          title: id,
          category: 'Push/Fold',
          prerequisites: prereqs,
          level: level);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns null when node is unlocked', () async {
    final nodes = [
      node('n1'),
      node('n2', prereqs: ['n1'])
    ];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService(SkillTreeBuildResult(tree: tree));
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    await tracker.markCompleted('n1');
    final svc = SkillTreeNodeLockReasonService(
      library: lib,
      progress: tracker,
      stageEvaluator: const SkillTreeStageGateEvaluator(),
      unlockEvaluator: SkillTreeUnlockEvaluator(progress: tracker),
    );
    final reason = await svc.getLockReason(nodes[1]);
    expect(reason, isNull);
  });

  test('reports missing prerequisite node', () async {
    final nodes = [
      node('n1'),
      node('n2', prereqs: ['n1'])
    ];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService(SkillTreeBuildResult(tree: tree));
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    final svc = SkillTreeNodeLockReasonService(
      library: lib,
      progress: tracker,
      stageEvaluator: const SkillTreeStageGateEvaluator(),
      unlockEvaluator: SkillTreeUnlockEvaluator(progress: tracker),
    );
    final reason = await svc.getLockReason(nodes[1]);
    expect(reason, startsWith('Завершите узел'));
  });

  test('reports locked stage', () async {
    final nodes = [
      node('n1', level: 0),
      node('n2', level: 1),
      node('n3', level: 2),
    ];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService(SkillTreeBuildResult(tree: tree));
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    await tracker.markCompleted('n1');
    final svc = SkillTreeNodeLockReasonService(
      library: lib,
      progress: tracker,
      stageEvaluator: const SkillTreeStageGateEvaluator(),
      unlockEvaluator: SkillTreeUnlockEvaluator(progress: tracker),
    );
    final reason = await svc.getLockReason(nodes[2]);
    expect(reason, startsWith('Завершите этап'));
  });
}
