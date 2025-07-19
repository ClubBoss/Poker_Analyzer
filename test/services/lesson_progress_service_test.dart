import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('markCompleted persists step id', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressService.instance.markCompleted('step1');
    expect(await LessonProgressService.instance.isCompleted('step1'), true);
    final completed = await LessonProgressService.instance.getCompletedSteps();
    expect(completed.contains('step1'), true);
  });
}
