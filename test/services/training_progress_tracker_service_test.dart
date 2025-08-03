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
}
