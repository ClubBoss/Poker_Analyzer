import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/stage_completion_celebration_service.dart';
import 'package:poker_analyzer/services/skill_tree_library_service.dart';
import 'package:poker_analyzer/services/track_recommendation_engine.dart';
import 'package:poker_analyzer/services/skill_tree_navigator.dart';

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

    expect(find.byType(AlertDialog), findsOneWidget);
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

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('celebrates track completion', (tester) async {
    final nodes = [node('a', 0), node('b', 1)];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService({
      'T': SkillTreeBuildResult(tree: tree),
    }, nodes);

    await tracker.markCompleted('a');
    await tracker.markCompleted('b');

    final svc = StageCompletionCelebrationService(
      library: lib,
      progress: tracker,
    );

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.checkAndCelebrateTrackCompletion('T');
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(await tracker.isTrackCompleted('T'), isTrue);
  });

  testWidgets('does not repeat track celebration', (tester) async {
    final nodes = [node('a', 0), node('b', 1)];
    final tree = builder.build(nodes).tree;
    final lib = _FakeLibraryService({
      'T': SkillTreeBuildResult(tree: tree),
    }, nodes);

    await tracker.markCompleted('a');
    await tracker.markCompleted('b');
    await tracker.markTrackCompleted('T');

    final svc = StageCompletionCelebrationService(
      library: lib,
      progress: tracker,
    );

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.checkAndCelebrateTrackCompletion('T');
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('offers next track recommendation', (tester) async {
    final nodes1 = [node('a', 0)];
    final nodes2 = [node('b', 0)];
    final tree1 = builder.build(nodes1).tree;
    final tree2 = builder.build(nodes2).tree;
    final lib = _FakeLibraryService({
      'T1': SkillTreeBuildResult(tree: tree1),
      'T2': SkillTreeBuildResult(tree: tree2),
    }, [...nodes1, ...nodes2]);

    await tracker.markCompleted('a');

    TrackRecommendationEngine.instance =
        TrackRecommendationEngine(library: lib);
    String opened = '';
    SkillTreeNavigator.instance = _RecordingSkillTreeNavigator((id) {
      opened = id;
    });

    final svc = StageCompletionCelebrationService(
      library: lib,
      progress: tracker,
    );

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.checkAndCelebrateTrackCompletion('T1');
    await tester.pumpAndSettle();

    expect(find.text('Следующий трек'), findsOneWidget);

    await tester.tap(find.text('Следующий трек'));
    await tester.pumpAndSettle();

    expect(opened, 'T2');

    TrackRecommendationEngine.instance = TrackRecommendationEngine();
    SkillTreeNavigator.instance = const SkillTreeNavigator();
  });
}

class _RecordingSkillTreeNavigator extends SkillTreeNavigator {
  final void Function(String) onOpen;
  const _RecordingSkillTreeNavigator(this.onOpen);

  @override
  Future<void> openTrack(String trackId) async {
    onOpen(trackId);
  }
}
