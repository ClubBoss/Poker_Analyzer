import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_path_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computeProgress returns 0 when nothing completed', () async {
    SharedPreferences.setMockInitialValues({'lesson_selected_track': 'mtt_pro'});
    final progress = await LessonPathProgressService.instance.computeProgress();
    expect(progress.completed, 0);
    expect(progress.total, 1);
    expect(progress.remainingIds, ['lesson1']);
    expect(progress.percent, 0);
  });

  test('computeProgress counts completed steps', () async {
    SharedPreferences.setMockInitialValues({
      'lesson_selected_track': 'mtt_pro',
      'lesson_completed_lesson1': true,
    });
    final progress = await LessonPathProgressService.instance.computeProgress();
    expect(progress.completed, 1);
    expect(progress.total, 1);
    expect(progress.completedIds, ['lesson1']);
    expect(progress.percent, 100);
  });
}
