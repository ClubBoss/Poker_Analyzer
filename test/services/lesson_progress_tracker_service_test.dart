import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_progress_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('markStepCompleted stores step', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressTrackerService.instance.load();
    await LessonProgressTrackerService.instance.markStepCompleted('step1');
    expect(await LessonProgressTrackerService.instance.isStepCompleted('step1'), true);
    final map = await LessonProgressTrackerService.instance.getCompletedSteps();
    expect(map['step1'], true);
  });
}
