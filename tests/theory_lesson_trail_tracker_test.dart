import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_lesson_trail_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TheoryLessonTrailTracker.instance.clearTrail();
  });

  test('records visits in order', () async {
    final tracker = TheoryLessonTrailTracker.instance;
    await tracker.recordVisit('l1');
    await tracker.recordVisit('l2');
    await tracker.recordVisit('l3');

    expect(tracker.getLastVisited(), 'l3');
    expect(tracker.getTrail(limit: 3), ['l3', 'l2', 'l1']);
  });
}
