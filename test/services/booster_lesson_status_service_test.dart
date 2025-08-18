import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/booster_lesson_status_service.dart';
import 'package:poker_analyzer/services/inbox_booster_tracker_service.dart';
import 'package:poker_analyzer/services/booster_path_history_service.dart';
import 'package:poker_analyzer/models/booster_lesson_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InboxBoosterTrackerService.instance.resetForTest();
  });

  test('determines new lesson status', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: '',
      content: '',
      tags: ['cbet'],
    );
    final service = BoosterLessonStatusService(
      tracker: InboxBoosterTrackerService.instance,
      history: BoosterPathHistoryService.instance,
    );
    final status = await service.getStatus(lesson);
    expect(status, BoosterLessonStatus.newLesson);
  });

  test('determines in progress status', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l2',
      title: '',
      content: '',
      tags: ['fold'],
    );
    await InboxBoosterTrackerService.instance.markShown('l2');
    final service = BoosterLessonStatusService(
      tracker: InboxBoosterTrackerService.instance,
      history: BoosterPathHistoryService.instance,
    );
    final status = await service.getStatus(lesson);
    expect(status, BoosterLessonStatus.inProgress);
  });

  test('determines repeated status', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l3',
      title: '',
      content: '',
      tags: ['call'],
    );
    await BoosterPathHistoryService.instance.markShown('l3', 'call');
    await BoosterPathHistoryService.instance.markCompleted('l3', 'call');
    await BoosterPathHistoryService.instance.markCompleted('l3', 'call');
    final service = BoosterLessonStatusService(
      tracker: InboxBoosterTrackerService.instance,
      history: BoosterPathHistoryService.instance,
    );
    final status = await service.getStatus(lesson);
    expect(status, BoosterLessonStatus.repeated);
  });

  test('determines skipped status', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l4',
      title: '',
      content: '',
      tags: ['raise'],
    );
    for (var i = 0; i < 5; i++) {
      await InboxBoosterTrackerService.instance.markShown('l4');
    }
    final service = BoosterLessonStatusService(
      tracker: InboxBoosterTrackerService.instance,
      history: BoosterPathHistoryService.instance,
    );
    final status = await service.getStatus(lesson);
    expect(status, BoosterLessonStatus.skipped);
  });
}
