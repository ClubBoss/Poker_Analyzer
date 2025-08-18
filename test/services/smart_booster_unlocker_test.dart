import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';
import 'package:poker_analyzer/models/mistake_tag_history_entry.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/goal_queue.dart';
import 'package:poker_analyzer/services/recap_booster_queue.dart';
import 'package:poker_analyzer/services/smart_booster_unlocker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/theory_tag_decay_tracker.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((l) => l.id == id, orElse: () => null);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final lc = tags.map((e) => e.toLowerCase()).toSet();
    final result = <TheoryMiniLessonNode>[];
    for (final l in lessons) {
      final tagsLc = l.tags.map((e) => e.toLowerCase());
      if (tagsLc.any(lc.contains)) result.add(l);
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

class _FakeMastery extends TagMasteryService {
  final Map<String, double> map;
  _FakeMastery(this.map)
    : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async => map;

  @override
  Future<List<String>> findWeakTags({double threshold = 0.7}) async {
    final result = <String>[];
    for (final e in map.entries) {
      if (e.value < threshold) result.add(e.key);
    }
    return result;
  }
}

class _FakeDecay extends TheoryTagDecayTracker {
  final Map<String, double> scores;
  _FakeDecay(this.scores) : super();

  @override
  Future<Map<String, double>> computeDecayScores({DateTime? now}) async {
    return scores;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    RecapBoosterQueue.instance.clear();
    GoalQueue.instance.clear();
  });

  test('schedules lessons based on weak mistake tags', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'BTN Overfold',
        content: '',
        tags: ['btn overfold'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'Loose Call',
        content: '',
        tags: ['loose call bb'],
      ),
    ];
    final history = [
      MistakeTagHistoryEntry(
        timestamp: DateTime.now(),
        packId: 'p1',
        spotId: 's1',
        tags: const [MistakeTag.overfoldBtn],
        evDiff: -1,
      ),
      MistakeTagHistoryEntry(
        timestamp: DateTime.now(),
        packId: 'p2',
        spotId: 's2',
        tags: const [MistakeTag.overfoldBtn],
        evDiff: -0.8,
      ),
      MistakeTagHistoryEntry(
        timestamp: DateTime.now(),
        packId: 'p3',
        spotId: 's3',
        tags: const [MistakeTag.looseCallBb],
        evDiff: -0.5,
      ),
    ];
    final mastery = _FakeMastery({'btn overfold': 0.4, 'loose call bb': 0.6});
    final unlocker = SmartBoosterUnlocker(
      mastery: mastery,
      lessons: _FakeLibrary(lessons),
      historyLoader: ({int limit = 10}) async => history,
      mistakeLimit: 10,
    );

    await unlocker.schedule();

    expect(RecapBoosterQueue.instance.getQueue(), ['l1']);
    expect(GoalQueue.instance.getQueue().map((e) => e.id).toList(), ['l2']);
  });

  test('prioritizes decayed tags when no recent mistakes', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'd1',
        title: 'Old Theory',
        content: '',
        tags: ['decayed'],
      ),
    ];
    final mastery = _FakeMastery({'decayed': 0.6});
    final unlocker = SmartBoosterUnlocker(
      mastery: mastery,
      lessons: _FakeLibrary(lessons),
      historyLoader: ({int limit = 10}) async => [],
      decayTracker: _FakeDecay({'decayed': 50}),
    );

    await unlocker.schedule();

    expect(RecapBoosterQueue.instance.getQueue(), isEmpty);
    expect(GoalQueue.instance.getQueue().map((e) => e.id).toList(), ['d1']);
  });
}
