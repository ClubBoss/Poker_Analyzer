import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/training_progress_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records and retrieves completed spots', () async {
    SharedPreferences.setMockInitialValues({});
    final service = TrainingProgressTrackerService.instance;
    expect(await service.getCompletedSpotIds('p1'), isEmpty);
    await service.recordSpotCompleted('p1', 's1');
    await service.recordSpotCompleted('p1', 's2');
    await service.recordSpotCompleted('p1', 's1');
    final ids = await service.getCompletedSpotIds('p1');
    expect(ids.length, 2);
    expect(ids, containsAll(['s1', 's2']));
  });

  test('checks performance requirements', () async {
    SharedPreferences.setMockInitialValues({
      'tpl_stat_prev': '{"accuracy":0.82,"last":0}',
      'tpl_prog_prev': 49,
    });
    final service = TrainingProgressTrackerService.instance;
    expect(
      await service.meetsPerformanceRequirements('prev',
          requiresAccuracy: 80, requiresVolume: 50),
      isTrue,
    );
    expect(
      await service.meetsPerformanceRequirements('prev',
          requiresAccuracy: 85, requiresVolume: 50),
      isFalse,
    );
    expect(
      await service.meetsPerformanceRequirements('prev',
          requiresAccuracy: 80, requiresVolume: 60),
      isFalse,
    );
  });
}
