import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_progress_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('markStepCompleted stores step for lesson', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressTrackerService.instance.load();
    await LessonProgressTrackerService.instance
        .markStepCompleted('lessonA', 'step1');
    expect(
        await LessonProgressTrackerService.instance
            .isStepCompleted('lessonA', 'step1'),
        true);
    final list = await LessonProgressTrackerService.instance
        .getCompletedSteps('lessonA');
    expect(list, ['step1']);
  });

  test('legacy flat methods still work', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressTrackerService.instance.load();
    await LessonProgressTrackerService.instance.markStepCompletedFlat('step2');
    expect(
        await LessonProgressTrackerService.instance
            .isStepCompletedFlat('step2'),
        true);
    final map =
        await LessonProgressTrackerService.instance.getCompletedStepsFlat();
    expect(map['step2'], true);
  });
}
