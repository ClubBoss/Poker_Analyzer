import 'package:flutter/material.dart';
import 'package:poker_analyzer/widgets/dark_alert_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_library_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/track_completion_celebration_service.dart';
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

  final tracker = SkillTreeNodeProgressTracker.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await tracker.resetForTest();
  });

  testWidgets('celebrates completed track', (tester) async {
    await tracker.markTrackCompleted('T');

    final svc = TrackCompletionCelebrationService(progress: tracker);

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.maybeCelebrate('T');
    await tester.pumpAndSettle();

    expect(find.byType(DarkAlertDialog), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('track_completion_shown_T'), isTrue);
  });

  testWidgets('does not repeat celebration', (tester) async {
    SharedPreferences.setMockInitialValues({'track_completion_shown_T': true});
    await tracker.resetForTest();
    await tracker.markTrackCompleted('T');

    final svc = TrackCompletionCelebrationService(progress: tracker);

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.maybeCelebrate('T');
    await tester.pump();

    expect(find.byType(DarkAlertDialog), findsNothing);
  });

  testWidgets('offers next track navigation', (tester) async {
    final node1 = SkillTreeNodeModel(
      id: 'a',
      title: 'A',
      category: 'T1',
      level: 0,
    );
    final node2 = SkillTreeNodeModel(
      id: 'b',
      title: 'B',
      category: 'T2',
      level: 0,
    );
    const builder = SkillTreeBuilderService();
    final tree1 = builder.build([node1]).tree;
    final tree2 = builder.build([node2]).tree;
    final lib = _FakeLibraryService(
      {
        'T1': SkillTreeBuildResult(tree: tree1),
        'T2': SkillTreeBuildResult(tree: tree2),
      },
      [node1, node2],
    );

    TrackRecommendationEngine.instance = TrackRecommendationEngine(
      library: lib,
    );
    String opened = '';
    SkillTreeNavigator.instance = _RecordingSkillTreeNavigator((id) {
      opened = id;
    });

    await tracker.markTrackCompleted('T1');

    final svc = TrackCompletionCelebrationService(progress: tracker);

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.maybeCelebrate('T1');
    await tester.pumpAndSettle();

    expect(find.text('Открыть следующий трек'), findsOneWidget);

    await tester.tap(find.text('Открыть следующий трек'));
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
