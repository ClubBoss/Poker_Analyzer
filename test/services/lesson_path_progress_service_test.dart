import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/lesson_path_progress_service.dart';
import 'package:poker_analyzer/services/lesson_progress_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computeProgress returns 0 when nothing completed', () async {
    SharedPreferences.setMockInitialValues({
      'lesson_selected_track': 'mtt_pro',
    });
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

  test('computeTrackProgress returns map for each track', () async {
    SharedPreferences.setMockInitialValues({});
    final map = await LessonPathProgressService.instance.computeTrackProgress();
    expect(map['mtt_pro'], 0);
    expect(map['live_exploit'], 0);
    expect(map['leak_fixer'], 0);
  });

  test('computeTrackProgress counts completed steps', () async {
    SharedPreferences.setMockInitialValues({
      'lesson_progress': '{"lesson1": true}',
    });
    await LessonProgressTrackerService.instance.load();
    final map = await LessonPathProgressService.instance.computeTrackProgress();
    expect(map['mtt_pro'], 100);
    expect(map['live_exploit'], 100);
    expect(map['leak_fixer'], 100);
  });

  test('computeTrackProgress includes yaml tracks', () async {
    SharedPreferences.setMockInitialValues({});
    await LessonProgressTrackerService.instance.load();
    final map = await LessonPathProgressService.instance.computeTrackProgress();
    expect(map.containsKey('yaml_sample'), true);
  });
}
