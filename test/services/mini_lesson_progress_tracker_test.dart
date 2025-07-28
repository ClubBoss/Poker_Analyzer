import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('markViewed increments count and sets timestamp', () async {
    final tracker = MiniLessonProgressTracker.instance;
    await tracker.markViewed('m1');
    await tracker.markViewed('m1');
    expect(await tracker.isCompleted('m1'), isFalse);
    expect(await tracker.lastViewed('m1'), isNotNull);
    final least = await tracker.getLeastViewed(['m1']);
    expect(least, 'm1');
  });

  test('markCompleted sets completed flag', () async {
    final tracker = MiniLessonProgressTracker.instance;
    await tracker.markCompleted('m2');
    expect(await tracker.isCompleted('m2'), isTrue);
  });

  test('getLeastViewed returns id with lowest count', () async {
    final tracker = MiniLessonProgressTracker.instance;
    await tracker.markViewed('a');
    await tracker.markViewed('b');
    await tracker.markViewed('b');
    final id = await tracker.getLeastViewed(['a', 'b']);
    expect(id, 'a');
  });
}
