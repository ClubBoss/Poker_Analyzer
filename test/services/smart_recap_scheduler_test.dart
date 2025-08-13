import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/smart_recap_scheduler.dart';
import 'package:poker_analyzer/services/skill_tag_decay_tracker.dart';
import 'package:poker_analyzer/services/recap_tag_analytics_service.dart';
import 'package:poker_analyzer/services/smart_recap_banner_controller.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/services/theory_boost_recap_linker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/tag_mastery_history_service.dart';
import 'package:poker_analyzer/models/recap_tag_performance.dart';

class _FakeDecay extends SkillTagDecayTracker {
  final List<String> tags;
  _FakeDecay(this.tags)
      : super(
            logs: SessionLogService(sessions: TrainingSessionService()),
            history: TagMasteryHistoryService());
  @override
  Future<List<String>> getDecayingTags(
      {int maxTags = 5,
      int recentSessions = 10,
      DateTime? now,
      double timeWeight = 0.5,
      double trendWeight = 0.5}) async {
    return tags;
  }
}

class _FakeAnalytics extends RecapTagAnalyticsService {
  final Map<String, double> map;
  _FakeAnalytics(this.map)
      : super(logs: SessionLogService(sessions: TrainingSessionService()));
  @override
  Future<Map<String, RecapTagPerformance>> computeRecapTagImprovements() async {
    return {
      for (final e in map.entries)
        e.key: RecapTagPerformance(tag: e.key, improvement: e.value)
    };
  }
}

class _FakeController extends SmartRecapBannerController {
  _FakeController() : super(sessions: TrainingSessionService());
  TheoryMiniLessonNode? queued;
  @override
  Future<void> queueBannerFor(TheoryMiniLessonNode lesson) async {
    queued = lesson;
  }
}

class _FakeLinker extends TheoryBoostRecapLinker {
  final TheoryMiniLessonNode lesson;
  const _FakeLinker(this.lesson) : super();
  @override
  Future<TheoryMiniLessonNode?> fetchLesson(String tag) async => lesson;
}

class _FakeLibrary implements MiniLessonLibraryService {
  final TheoryMiniLessonNode lesson;
  _FakeLibrary(this.lesson);
  @override
  List<TheoryMiniLessonNode> get all => [lesson];
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
  @override
  TheoryMiniLessonNode? getById(String id) => lesson.id == id ? lesson : null;
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [lesson];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [lesson];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('queues banner for decaying tag', () async {
    final lesson =
        const TheoryMiniLessonNode(id: 'l1', title: 't', content: '');
    final controller = _FakeController();
    final scheduler = SmartRecapScheduler(
      decay: _FakeDecay(['push']),
      analytics: _FakeAnalytics({'push': 0}),
      controller: controller,
      theoryLinker: _FakeLinker(lesson),
      library: _FakeLibrary(lesson),
    );
    await scheduler.start(interval: const Duration(milliseconds: 10));
    await Future.delayed(const Duration(milliseconds: 20));
    expect(controller.queued?.id, 'l1');
    await scheduler.dispose();
  });
}
