import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/skill_tree_build_result.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/reward_card_style_tuner_service.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_library_service.dart';
import 'package:poker_analyzer/services/track_reward_preview_service.dart';

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

class _FakeStyleTuner implements RewardCardStyleTunerService {
  const _FakeStyleTuner();

  @override
  RewardCardStyle getStyle(String trackId) => const RewardCardStyle(
    gradient: [Colors.black, Colors.white],
    icon: Icons.star,
    badgeText: 'Styled!',
    badgeColor: Colors.red,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'reward_granted_T': true});
  });

  testWidgets('builds preview card without completion badge', (tester) async {
    final node = SkillTreeNodeModel(
      id: 'n1',
      title: 'Test Track',
      category: 'T',
      level: 0,
    );
    const builder = SkillTreeBuilderService();
    final tree = builder.build([node]).tree;
    final lib = _FakeLibraryService(
      {'T': SkillTreeBuildResult(tree: tree)},
      [node],
    );
    final svc = await TrackRewardPreviewService.create(
      library: lib,
      styleTuner: const _FakeStyleTuner(),
    );

    await tester.pumpWidget(MaterialApp(home: svc.buildPreviewCard('T')));

    expect(find.text('Test Track'), findsOneWidget);
    expect(find.text('Styled!'), findsNothing);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
