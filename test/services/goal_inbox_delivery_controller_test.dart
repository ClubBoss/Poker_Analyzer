import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/xp_guided_goal.dart';
import 'package:poker_analyzer/services/goal_inbox_delivery_controller.dart';
import 'package:poker_analyzer/services/goal_slot_allocator.dart';
import 'package:poker_analyzer/services/inbox_booster_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InboxBoosterTrackerService.instance.resetForTest();
  });

  XPGuidedGoal goal(String id, int xp) =>
      XPGuidedGoal(id: id, label: id, xp: xp, source: 't', onComplete: () {});

  test('filters by slot and prioritizes by xp', () async {
    final controller = GoalInboxDeliveryController(
      tracker: InboxBoosterTrackerService.instance,
    );
    controller.updateAssignments([
      GoalSlotAssignment(goal: goal('g1', 10), slot: 'theory'),
      GoalSlotAssignment(goal: goal('g2', 20), slot: 'home'),
      GoalSlotAssignment(goal: goal('g3', 5), slot: 'postrecap'),
    ]);
    final res = await controller.getInboxGoals();
    expect(res.length, 2);
    expect(res.first.id, 'g2');
    expect(res[1].id, 'g1');
  });

  test('excludes previously shown goals', () async {
    await InboxBoosterTrackerService.instance.markShown('g1');
    final controller = GoalInboxDeliveryController(
      tracker: InboxBoosterTrackerService.instance,
    );
    controller.updateAssignments([
      GoalSlotAssignment(goal: goal('g1', 10), slot: 'theory'),
      GoalSlotAssignment(goal: goal('g2', 20), slot: 'home'),
    ]);
    final res = await controller.getInboxGoals();
    expect(res.length, 1);
    expect(res.first.id, 'g2');
  });

  test('marks goals as shown', () async {
    final controller = GoalInboxDeliveryController(
      tracker: InboxBoosterTrackerService.instance,
    );
    controller.updateAssignments([
      GoalSlotAssignment(goal: goal('g1', 10), slot: 'theory'),
    ]);
    final res = await controller.getInboxGoals();
    expect(res.length, 1);
    final stats = await InboxBoosterTrackerService.instance
        .getInteractionStats();
    expect(stats['g1']?['shows'], 1);
  });
}
