import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_progress_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('markStepCompleted stores step and marks lesson', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressTrackerService.instance.load();
    await LessonProgressTrackerService.instance
        .markStepCompleted('lessonA', 'step1');
    final steps =
        await LessonProgressTrackerService.instance.getCompletedSteps('lessonA');
    expect(steps.contains('step1'), true);
    final lessons =
        await LessonProgressTrackerService.instance.getCompletedLessons();
    expect(lessons.contains('lessonA'), true);
  });

  test('legacy flat methods still work', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressTrackerService.instance.load();
    await LessonProgressTrackerService.instance.markStepCompletedFlat('step2');
    final map =
        await LessonProgressTrackerService.instance.getCompletedStepsFlat();
    expect(map['step2'], true);
  });

  test('reset clears all progress', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressTrackerService.instance.load();
    await LessonProgressTrackerService.instance
        .markStepCompleted('lessonX', 's1');
    await LessonProgressTrackerService.instance.reset();
    final lessons =
        await LessonProgressTrackerService.instance.getCompletedLessons();
    final steps =
        await LessonProgressTrackerService.instance.getCompletedSteps('lessonX');
    expect(lessons.isEmpty, true);
    expect(steps.isEmpty, true);
  });
}
