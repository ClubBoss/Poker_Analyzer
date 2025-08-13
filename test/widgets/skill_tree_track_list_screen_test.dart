import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_track_progress_service.dart';
import 'package:poker_analyzer/services/skill_tree_track_state_evaluator.dart';
import 'package:poker_analyzer/screens/skill_tree_track_list_screen.dart';
import 'package:poker_analyzer/models/skill_tree_completion_badge.dart';
import 'package:poker_analyzer/services/skill_tree_completion_badge_service.dart';

class _FakeEvaluator extends SkillTreeTrackStateEvaluator {
  final List<TrackStateEntry> entries;
  _FakeEvaluator(this.entries)
      : super(progressService: SkillTreeTrackProgressService());

  @override
  Future<List<TrackStateEntry>> evaluateStates() async => entries;
}

class _FakeBadgeService extends SkillTreeCompletionBadgeService {
  final Map<String, SkillTreeCompletionBadge> map;
  const _FakeBadgeService(this.map) : super();

  @override
  Future<List<SkillTreeCompletionBadge>> getBadges() async =>
      map.values.toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();
  SkillTreeNodeModel node(String id, String cat) =>
      SkillTreeNodeModel(id: id, title: id, category: cat);

  testWidgets('orders tracks by state', (tester) async {
    final treeA = builder.build([node('a1', 'A')]).tree;
    final treeB = builder.build([node('b1', 'B')]).tree;
    final treeC = builder.build([node('c1', 'C')]).tree;
    final treeD = builder.build([node('d1', 'D')]).tree;

    final entries = [
      TrackStateEntry(
        progress: const TrackProgressEntry(
            tree: treeB, completionRate: 0.0, isCompleted: false),
        state: SkillTreeTrackState.unlocked,
      ),
      TrackStateEntry(
        progress: const TrackProgressEntry(
            tree: treeD, completionRate: 0.3, isCompleted: false),
        state: SkillTreeTrackState.inProgress,
      ),
      TrackStateEntry(
        progress: const TrackProgressEntry(
            tree: treeA, completionRate: 1.0, isCompleted: true),
        state: SkillTreeTrackState.completed,
      ),
      TrackStateEntry(
        progress: const TrackProgressEntry(
            tree: treeC, completionRate: 0.0, isCompleted: false),
        state: SkillTreeTrackState.locked,
      ),
    ];

    final badgeMap = {
      'A': const SkillTreeCompletionBadge(
          trackId: 'A', percentComplete: 1.0, isComplete: true),
      'B': const SkillTreeCompletionBadge(
          trackId: 'B', percentComplete: 0.0, isComplete: false),
      'C': const SkillTreeCompletionBadge(
          trackId: 'C', percentComplete: 0.0, isComplete: false),
      'D': const SkillTreeCompletionBadge(
          trackId: 'D', percentComplete: 0.3, isComplete: false),
    };

    await tester.pumpWidget(MaterialApp(
      home: SkillTreeTrackListScreen(
        evaluator: _FakeEvaluator(entries),
        badgeService: _FakeBadgeService(badgeMap),
        reloadLibrary: false,
      ),
    ));
    await tester.pumpAndSettle();

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    final titles = tiles.map((t) => (t.title as Text).data).toList();
    expect(titles, ['B', 'D', 'A', 'C']);
  });
}
