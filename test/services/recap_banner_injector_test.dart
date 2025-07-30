import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/recap_banner_injector.dart';
import 'package:poker_analyzer/services/recap_fatigue_evaluator.dart';
import 'package:poker_analyzer/services/recap_history_tracker.dart';
import 'package:poker_analyzer/services/recap_opportunity_detector.dart';
import 'package:poker_analyzer/services/smart_recap_banner_controller.dart';
import 'package:poker_analyzer/services/smart_recap_suggestion_engine.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/tag_retention_tracker.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';

class _FakeEngine extends SmartRecapSuggestionEngine {
  final StreamController<TheoryMiniLessonNode> ctrl;
  _FakeEngine(this.ctrl) : super();
  @override
  Stream<TheoryMiniLessonNode> get nextRecap => ctrl.stream;
  @override
  Future<void> start({Duration interval = const Duration(hours: 1)}) async {}
}

class _FakeDetector extends RecapOpportunityDetector {
  final bool value;
  _FakeDetector(this.value)
      : super(
          retention: TagRetentionTracker(
            mastery: TagMasteryService(
              logs: SessionLogService(sessions: TrainingSessionService()),
            ),
          ),
        );
  @override
  Future<bool> isGoodRecapMoment() async => value;
}

class _FakeFatigue extends RecapFatigueEvaluator {
  final bool value;
  _FakeFatigue(this.value) : super(tracker: RecapHistoryTracker.instance);
  @override
  Future<bool> isFatigued(String lessonId) async => value;
}

class _FakeController extends SmartRecapBannerController {
  int count = 0;
  TheoryMiniLessonNode? last;
  _FakeController() : super(sessions: TrainingSessionService());
  @override
  Future<void> triggerBannerIfNeeded([TheoryMiniLessonNode? lesson]) async {
    count++;
    last = lesson;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapHistoryTracker.instance.resetForTest();
  });

  test('injects banner on suggestion', () async {
    final c = StreamController<TheoryMiniLessonNode>();
    final engine = _FakeEngine(c);
    final controller = _FakeController();
    final service = RecapBannerInjector(
      engine: engine,
      detector: _FakeDetector(true),
      fatigue: _FakeFatigue(false),
      controller: controller,
      sessions: TrainingSessionService(),
    );
    await service.start();
    c.add(const TheoryMiniLessonNode(id: 'l1', title: 't', content: ''));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(controller.count, 1);
    expect(controller.last?.id, 'l1');
    await service.dispose();
  });

  test('skips when not a good moment', () async {
    final c = StreamController<TheoryMiniLessonNode>();
    final engine = _FakeEngine(c);
    final controller = _FakeController();
    final service = RecapBannerInjector(
      engine: engine,
      detector: _FakeDetector(false),
      fatigue: _FakeFatigue(false),
      controller: controller,
      sessions: TrainingSessionService(),
    );
    await service.start();
    c.add(const TheoryMiniLessonNode(id: 'l1', title: 't', content: ''));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(controller.count, 0);
    await service.dispose();
  });
}
