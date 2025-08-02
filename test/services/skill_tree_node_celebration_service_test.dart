import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/skill_tree_node_celebration_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';

class _FakeOverlay {
  int calls = 0;
  void call(BuildContext context) {
    calls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tracker = SkillTreeNodeProgressTracker.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await tracker.resetForTest();
  });

  testWidgets('celebrates when node completed', (tester) async {
    await tracker.markCompleted('A');
    final overlay = _FakeOverlay();
    final service = SkillTreeNodeCelebrationService(showOverlay: overlay.call);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(key: key, home: const SizedBox()));
    await service.maybeCelebrate(key.currentContext!, 'A');
    expect(overlay.calls, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('skill_node_celebrated_A'), isTrue);
  });

  testWidgets('does not repeat celebration', (tester) async {
    await tracker.markCompleted('A');
    SharedPreferences.setMockInitialValues({'skill_node_celebrated_A': true});
    final overlay = _FakeOverlay();
    final service = SkillTreeNodeCelebrationService(showOverlay: overlay.call);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(key: key, home: const SizedBox()));
    await service.maybeCelebrate(key.currentContext!, 'A');
    expect(overlay.calls, 0);
  });
}
