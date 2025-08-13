import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/recap_to_drill_launcher.dart';
import 'package:poker_analyzer/services/smart_recap_banner_controller.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/recap_history_tracker.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';

class _FakeLauncher extends TrainingSessionLauncher {
  int count = 0;
  List<String>? tags;
  const _FakeLauncher();
  @override
  Future<void> launchForMiniLesson(TheoryMiniLessonNode lesson,
      {List<String>? sessionTags}) async {
    count++;
    tags = sessionTags;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapHistoryTracker.instance.resetForTest();
  });

  testWidgets('launches drill and dismisses banner', (tester) async {
    final sessions = TrainingSessionService();
    final controller = SmartRecapBannerController(sessions: sessions);
    final launcher = _FakeLauncher();
    final service = RecapToDrillLauncher(
      banner: controller,
      sessions: sessions,
      launcher: launcher,
    );

    await controller.showManually(
        const TheoryMiniLessonNode(id: 'l1', title: 't', content: ''));
    await tester.pump();
    await service
        .launch(const TheoryMiniLessonNode(id: 'l1', title: 't', content: ''));

    expect(launcher.count, 1);
    expect(launcher.tags, ['recap', 'reinforcement']);
    expect(controller.shouldShowBanner(), isFalse);
    final events = await RecapHistoryTracker.instance.getHistory();
    expect(events.first.eventType, 'drillLaunch');
    expect(events.first.lessonId, 'l1');
  });

  testWidgets('does nothing when session active', (tester) async {
    final sessions = TrainingSessionService();
    final controller = SmartRecapBannerController(sessions: sessions);
    final launcher = _FakeLauncher();
    final service = RecapToDrillLauncher(
      banner: controller,
      sessions: sessions,
      launcher: launcher,
    );

    // Start dummy session
    await sessions.startSession(
      TrainingPackTemplate(id: 't', name: 'n'),
      persist: false,
    );

    await controller.showManually(
        const TheoryMiniLessonNode(id: 'l1', title: 't', content: ''));
    await tester.pump();
    await service
        .launch(const TheoryMiniLessonNode(id: 'l1', title: 't', content: ''));

    expect(launcher.count, 0);
    expect(launcher.tags, isNull);
    expect(controller.shouldShowBanner(), isTrue);
    final events = await RecapHistoryTracker.instance.getHistory();
    expect(events, isEmpty);
  });
}
