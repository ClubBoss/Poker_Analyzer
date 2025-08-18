import 'package:flutter/material.dart';
import 'package:poker_analyzer/widgets/dark_alert_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/main.dart';
import 'package:poker_analyzer/services/track_completion_reward_service.dart';
import 'package:poker_analyzer/services/track_reward_unlocker_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tracker = SkillTreeNodeProgressTracker.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await tracker.resetForTest();
  });

  testWidgets('shows reward dialog after track completion', (tester) async {
    await tracker.markTrackCompleted('T');
    final granted = await TrackCompletionRewardService.instance.grantReward(
      'T',
    );
    final svc = TrackRewardUnlockerService(progress: tracker);

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    if (granted) {
      await svc.unlockReward('T');
    }
    await tester.pumpAndSettle();

    expect(find.byType(DarkAlertDialog), findsOneWidget);
  });

  testWidgets('skips reward if track incomplete', (tester) async {
    final svc = TrackRewardUnlockerService(progress: tracker);

    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
    );

    await svc.unlockReward('T');
    await tester.pump();

    expect(find.byType(DarkAlertDialog), findsNothing);
  });
}
