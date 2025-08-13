import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_progress_analytics_service.dart';
import 'package:poker_analyzer/services/skill_tree_celebration_trigger_service.dart';
import 'package:poker_analyzer/services/skill_tree_milestone_overlay_service.dart';
import 'package:poker_analyzer/services/skill_tree_motivational_hint_engine.dart';

class _FakeOverlay extends SkillTreeMilestoneOverlayService {
  int calls = 0;
  _FakeOverlay() : super(engine: const SkillTreeMotivationalHintEngine());

  @override
  Future<void> maybeShow(
      BuildContext context, SkillTreeProgressStats stats) async {
    calls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final builder = const SkillTreeBuilderService();
  final tracker = SkillTreeNodeProgressTracker.instance;

  SkillTreeNodeModel node(String id, {List<String>? prereqs}) =>
      SkillTreeNodeModel(
          id: id, title: id, category: 'PF', prerequisites: prereqs);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await tracker.resetForTest();
  });

  testWidgets('celebrates when tree completed', (tester) async {
    final tree = builder.build([
      node('a'),
      node('b', prereqs: ['a'])
    ]).tree;
    await tracker.markCompleted('a');
    await tracker.markCompleted('b');
    final overlay = _FakeOverlay();
    final service = SkillTreeCelebrationTriggerService(overlay: overlay);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(key: key, home: const SizedBox()));
    await service.maybeCelebrate(key.currentContext!, tree);
    expect(overlay.calls, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('celebration_done_PF'), isTrue);
  });

  testWidgets('does not repeat celebration', (tester) async {
    final tree = builder.build([node('a')]).tree;
    await tracker.markCompleted('a');
    SharedPreferences.setMockInitialValues({'celebration_done_PF': true});
    final overlay = _FakeOverlay();
    final service = SkillTreeCelebrationTriggerService(overlay: overlay);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(key: key, home: const SizedBox()));
    await service.maybeCelebrate(key.currentContext!, tree);
    expect(overlay.calls, 0);
  });
}
