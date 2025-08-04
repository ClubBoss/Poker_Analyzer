import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/training_path_progress_tracker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late TrainingPathProgressTrackerService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = const TrainingPathProgressTrackerService();
  });

  test('marks nodes as completed', () async {
    await service.markCompleted('starter_pushfold_10bb');
    final completed = await service.getCompletedNodeIds();
    expect(completed, {'starter_pushfold_10bb'});
  });

  test('computes unlocked nodes based on prerequisites', () async {
    // Initially only the first node should be unlocked
    var unlocked = await service.getUnlockedNodeIds();
    expect(unlocked, {'starter_pushfold_10bb'});

    // Complete first node -> second unlocks
    await service.markCompleted('starter_pushfold_10bb');
    unlocked = await service.getUnlockedNodeIds();
    expect(unlocked.contains('starter_postflop_basics'), isTrue);

    // Complete second node -> third unlocks
    await service.markCompleted('starter_postflop_basics');
    unlocked = await service.getUnlockedNodeIds();
    expect(
      unlocked.containsAll({
        'starter_pushfold_10bb',
        'starter_postflop_basics',
        'advanced_pushfold_15bb',
      }),
      isTrue,
    );
  });
}
