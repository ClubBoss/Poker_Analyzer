import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/theory_lesson_review_queue.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);
  @override
  List<TheoryMiniLessonNode> get all => items;
  @override
  TheoryMiniLessonNode? getById(String id) =>
      items.firstWhere((e) => e.id == id, orElse: () => null);
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

class _FakeLogService extends SessionLogService {
  final List<SessionLog> entries;
  _FakeLogService(this.entries) : super(sessions: TrainingSessionService());
  @override
  Future<void> load() async {}
  @override
  List<SessionLog> get logs => List.unmodifiable(entries);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getNextLessonsToReview orders lessons by priority', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'mini_lesson_progress_l1':
          '{"viewCount":2,"lastViewed":"${now.subtract(const Duration(days: 10)).toIso8601String()}","completed":false}',
      'mini_lesson_progress_l2':
          '{"viewCount":1,"lastViewed":"${now.subtract(const Duration(days: 5)).toIso8601String()}","completed":true}',
      'mini_lesson_progress_l3':
          '{"viewCount":1,"lastViewed":"${now.subtract(const Duration(days: 2)).toIso8601String()}","completed":false}',
    });

    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: ['a'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: '',
        tags: ['b'],
      ),
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'L3',
        content: '',
        tags: ['a', 'b'],
      ),
    ];

    final logs = [
      SessionLog(
        tags: const [],
        sessionId: 's1',
        templateId: 'p1',
        startedAt: now,
        completedAt: now,
        correctCount: 0,
        mistakeCount: 0,
        categories: {'a': 3, 'b': 1},
      ),
    ];

    final queue = TheoryLessonReviewQueue(
      library: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
      logs: _FakeLogService(logs),
    );

    final result = await queue.getNextLessonsToReview(limit: 3);
    expect(result.map((e) => e.id).toList(), ['l3', 'l1', 'l2']);
  });
}
