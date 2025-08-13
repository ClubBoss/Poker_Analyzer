import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/theory_reinforcement_banner_controller.dart';
import 'package:poker_analyzer/services/recap_completion_tracker.dart';
import 'package:poker_analyzer/services/theory_boost_trigger_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeTrigger extends TheoryBoostTriggerService {
  final bool value;
  _FakeTrigger(this.value) : super();
  @override
  Future<bool> shouldTriggerBoost(String tag) async => value;
}

class _FakeLibrary extends MiniLessonLibraryService {
  final TheoryMiniLessonNode lesson;
  _FakeLibrary(this.lesson);
  @override
  Future<void> loadAll() async {}
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [lesson];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapCompletionTracker.instance.resetForTest();
  });

  test('shows banner when trigger passes', () async {
    final lesson =
        const TheoryMiniLessonNode(id: 'l1', title: 't', content: '');
    final controller = TheoryReinforcementBannerController(
      trigger: _FakeTrigger(true),
      library: _FakeLibrary(lesson),
      cooldown: Duration.zero,
    );
    await RecapCompletionTracker.instance
        .logCompletion('r1', 'tag', const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);
    expect(controller.shouldShowBanner(), isTrue);
    expect(controller.getPendingBannerLesson()?.id, 'l1');
    controller.dispose();
  });

  test('respects cooldown between banners', () async {
    final lesson =
        const TheoryMiniLessonNode(id: 'l1', title: 't', content: '');
    final controller = TheoryReinforcementBannerController(
      trigger: _FakeTrigger(true),
      library: _FakeLibrary(lesson),
      cooldown: const Duration(hours: 1),
    );
    await RecapCompletionTracker.instance
        .logCompletion('r1', 'tag', const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);
    controller.markBannerDismissed();
    await RecapCompletionTracker.instance
        .logCompletion('r2', 'tag', const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);
    expect(controller.shouldShowBanner(), isFalse);
    controller.dispose();
  });
}
