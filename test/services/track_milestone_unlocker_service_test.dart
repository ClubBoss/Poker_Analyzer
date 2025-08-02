import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/track_milestone_unlocker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('initializes and unlocks milestones', () async {
    final svc = TrackMilestoneUnlockerService.instance;
    await svc.initializeMilestones('T');

    var states = await svc.getMilestoneStates(
      trackId: 'T',
      totalStages: 3,
      completedStages: {},
    );
    expect(states[0], MilestoneState.unlocked);
    expect(states[1], MilestoneState.locked);

    await svc.unlockNextStage('T');

    states = await svc.getMilestoneStates(
      trackId: 'T',
      totalStages: 3,
      completedStages: {0},
    );
    expect(states[0], MilestoneState.completed);
    expect(states[1], MilestoneState.unlocked);
  });
}
