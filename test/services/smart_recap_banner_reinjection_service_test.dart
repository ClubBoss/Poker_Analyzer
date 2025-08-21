import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/smart_recap_banner_reinjection_service.dart';
import 'package:poker_analyzer/services/recap_auto_repeat_scheduler.dart';
import 'package:poker_analyzer/services/smart_recap_banner_controller.dart';
import 'package:poker_analyzer/services/recap_fatigue_evaluator.dart';
import 'package:poker_analyzer/services/theory_recap_suppression_engine.dart';
import 'package:poker_analyzer/services/smart_theory_recap_dismissal_memory.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/recap_history_tracker.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);
  @override
  List<TheoryMiniLessonNode> get all => items;
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
  @override
  TheoryMiniLessonNode? getById(String id) =>
      items.firstWhere((e) => e.id == id, orElse: () => null);
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

class _FakeController extends SmartRecapBannerController {
  _FakeController() : super(sessions: TrainingSessionService());
  int count = 0;
  TheoryMiniLessonNode? last;
  @override
  Future<void> showManually(TheoryMiniLessonNode lesson) async {
    count++;
    last = lesson;
  }
}

class _FakeSuppression extends TheoryRecapSuppressionEngine {
  final bool value;
  _FakeSuppression(this.value) : super();
  @override
  Future<bool> shouldSuppress({
    required String lessonId,
    required String trigger,
  }) async => value;
}

class _FakeDismissal extends SmartTheoryRecapDismissalMemory {
  final bool value;
  _FakeDismissal(this.value) : super._();
  @override
  Future<bool> shouldThrottle(String key) async => value;
}

class _FakeFatigue extends RecapFatigueEvaluator {
  final bool value;
  _FakeFatigue(this.value) : super(tracker: RecapHistoryTracker.instance);
  @override
  Future<bool> isFatigued(String lessonId) async => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapAutoRepeatScheduler.instance.resetForTest();
    RecapHistoryTracker.instance.resetForTest();
  });

  test('shows due recap banner', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final lib = _FakeLibrary([lesson]);
    final controller = _FakeController();
    final service = SmartRecapBannerReinjectionService(
      scheduler: RecapAutoRepeatScheduler.instance,
      library: lib,
      controller: controller,
      fatigue: _FakeFatigue(false),
      suppression: _FakeSuppression(false),
      dismissal: _FakeDismissal(false),
    );
    await RecapAutoRepeatScheduler.instance.scheduleRepeat('l1', Duration.zero);
    await service.start(interval: const Duration(milliseconds: 10));
    await Future.delayed(const Duration(milliseconds: 20));
    expect(controller.count, 1);
    expect(controller.last?.id, 'l1');
    await service.dispose();
  });

  test('skips when suppressed', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final lib = _FakeLibrary([lesson]);
    final controller = _FakeController();
    final service = SmartRecapBannerReinjectionService(
      scheduler: RecapAutoRepeatScheduler.instance,
      library: lib,
      controller: controller,
      fatigue: _FakeFatigue(false),
      suppression: _FakeSuppression(true),
      dismissal: _FakeDismissal(false),
    );
    await RecapAutoRepeatScheduler.instance.scheduleRepeat('l1', Duration.zero);
    await service.start(interval: const Duration(milliseconds: 10));
    await Future.delayed(const Duration(milliseconds: 20));
    expect(controller.count, 0);
    await service.dispose();
  });
}
