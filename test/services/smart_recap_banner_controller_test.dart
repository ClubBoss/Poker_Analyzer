import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/smart_recap_banner_controller.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/smart_theory_recap_engine.dart';
import 'package:poker_analyzer/services/theory_recap_suppression_engine.dart';
import 'package:poker_analyzer/services/smart_theory_recap_dismissal_memory.dart';
import 'package:poker_analyzer/services/recap_fatigue_evaluator.dart';
import 'package:poker_analyzer/services/recap_history_tracker.dart';
import 'package:poker_analyzer/services/theory_booster_suggestion_engine.dart';

class _FakeRecapEngine extends SmartTheoryRecapEngine {
  final TheoryMiniLessonNode? lesson;
  const _FakeRecapEngine(this.lesson);
  @override
  Future<TheoryMiniLessonNode?> getNextRecap() async => lesson;
}

class _FakeSuppression extends TheoryRecapSuppressionEngine {
  final bool value;
  _FakeSuppression(this.value) : super();
  @override
  Future<bool> shouldSuppress({
    required String lessonId,
    required String trigger,
  }) async =>
      value;
}

class _FakeFatigue extends RecapFatigueEvaluator {
  final bool value;
  _FakeFatigue(this.value) : super(tracker: RecapHistoryTracker.instance);
  @override
  Future<bool> isFatigued(String lessonId) async => value;
}

class _FakeDismissal extends SmartTheoryRecapDismissalMemory {
  final bool value;
  _FakeDismissal(this.value) : super._();
  @override
  Future<bool> shouldThrottle(String key) async => value;
}

class _FakeBoosterEngine extends TheoryBoosterSuggestionEngine {
  final List<TheoryMiniLessonNode> boosters;
  const _FakeBoosterEngine(this.boosters) : super();
  @override
  Future<List<TheoryMiniLessonNode>> suggestBoosters({
    int maxCount = 3,
  }) async =>
      boosters;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapHistoryTracker.instance.resetForTest();
  });

  test('fallbacks to boosters when no recap', () async {
    final booster = const TheoryMiniLessonNode(
      id: 'b1',
      title: 't',
      content: '',
    );
    final controller = SmartRecapBannerController(
      engine: const _FakeRecapEngine(null),
      suppression: _FakeSuppression(false),
      dismissal: _FakeDismissal(false),
      fatigue: _FakeFatigue(false),
      boosterEngine: _FakeBoosterEngine([booster]),
      sessions: TrainingSessionService(),
    );

    await controller.triggerBannerIfNeeded();
    expect(controller.getBoosterLessons().length, 1);
    expect(controller.shouldShowBanner(), isTrue);
    expect(controller.getPendingLesson(), isNull);
  });

  test('uses boosters when recap suppressed', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final booster = const TheoryMiniLessonNode(
      id: 'b1',
      title: 'b',
      content: '',
    );
    final controller = SmartRecapBannerController(
      engine: _FakeRecapEngine(lesson),
      suppression: _FakeSuppression(true),
      dismissal: _FakeDismissal(false),
      fatigue: _FakeFatigue(false),
      boosterEngine: _FakeBoosterEngine([booster]),
      sessions: TrainingSessionService(),
    );

    await controller.triggerBannerIfNeeded();
    expect(controller.getBoosterLessons().first.id, 'b1');
    expect(controller.getPendingLesson(), isNull);
  });
}
