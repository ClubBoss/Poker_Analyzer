import 'package:flutter/material.dart';
import 'package:poker_analyzer/widgets/dark_alert_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/stage_completion_celebration_service.dart';
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
  List<SkillTreeBuildResult> getAllTracks() => _trees.values.toList();

  @override
  List<SkillTreeNodeModel> getAllNodes() => List.unmodifiable(_nodes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id, int level) =>
      SkillTreeNodeModel(id: id, title: id, category: 'T', level: level);

  final tracker = SkillTreeNodeProgressTracker.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await tracker.resetForTest();
  });

  testWidgets('celebrates newly completed stage', (tester) async {
    final nodes = [node('a', 0), node('b', 1)];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService({
      'T': SkillTreeBuildResult(tree: tree),
    }, nodes);

    await tracker.markCompleted('a');

    final svc = StageCompletionCelebrationService(
      library: lib,
      progress: tracker,
    );

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.checkAndCelebrate('T');
    await tester.pumpAndSettle();

    expect(find.byType(DarkAlertDialog), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('stage_celebrated_T_0'), isTrue);
  });

  testWidgets('does not repeat celebration', (tester) async {
    SharedPreferences.setMockInitialValues({'stage_celebrated_T_0': true});
    await tracker.resetForTest();
    final nodes = [node('a', 0)];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService({
      'T': SkillTreeBuildResult(tree: tree),
    }, nodes);

    await tracker.markCompleted('a');

    final svc = StageCompletionCelebrationService(
      library: lib,
      progress: tracker,
    );

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.checkAndCelebrate('T');
    await tester.pump();

    expect(find.byType(DarkAlertDialog), findsNothing);
  });
}
