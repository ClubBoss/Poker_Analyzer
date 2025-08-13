import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_smart_entry_point_selector.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_lesson_review_queue.dart';

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

class _FakeReview extends TheoryLessonReviewQueue {
  final List<TheoryMiniLessonNode> items;
  _FakeReview(this.items) : super();
  @override
  Future<List<TheoryMiniLessonNode>> getNextLessonsToReview({
    int limit = 5,
    Set<String> focusTags = const {},
  }) async {
    return items.take(limit).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('prefers unfinished lesson matching focus tag', () async {
    final lessons = [
      const TheoryMiniLessonNode(
          id: 'l1', title: 'A', content: '', tags: ['a']),
      const TheoryMiniLessonNode(
          id: 'l2', title: 'B', content: '', tags: ['b']),
    ];
    final selector = TheorySmartEntryPointSelector(
      library: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
      review: _FakeReview([]),
    );
    final res = await selector.pickSmartStartLesson(focusTags: {'b'});
    expect(res?.id, 'l2');
  });

  test('falls back to review queue when no unfinished match', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'mini_lesson_progress_l2': jsonEncode({
        'completed': true,
        'viewCount': 1,
        'lastViewed': now.toIso8601String()
      }),
    });
    final lessons = [
      const TheoryMiniLessonNode(
          id: 'l1', title: 'A', content: '', tags: ['a']),
      const TheoryMiniLessonNode(
          id: 'l2', title: 'B', content: '', tags: ['b']),
    ];
    final selector = TheorySmartEntryPointSelector(
      library: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
      review: _FakeReview([lessons.first]),
    );
    final res = await selector.pickSmartStartLesson(focusTags: {'b'});
    expect(res?.id, 'l1');
  });

  test('returns random unfinished lesson when no data', () async {
    final lessons = [
      const TheoryMiniLessonNode(
          id: 'l1', title: 'A', content: '', tags: ['a']),
      const TheoryMiniLessonNode(
          id: 'l2', title: 'B', content: '', tags: ['b']),
    ];
    final selector = TheorySmartEntryPointSelector(
      library: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
      review: _FakeReview([]),
    );
    final res = await selector.pickSmartStartLesson();
    expect(res, isNotNull);
    expect(['l1', 'l2'], contains(res!.id));
  });
}
