
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/widgets/theory_lesson_context_overlay.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];
}

class _FakeReview extends TheoryLessonReviewQueue {
  _FakeReview() : super();
  @override
  Future<List<TheoryMiniLessonNode>> getNextLessonsToReview({
    int limit = 5,
    Set<String> focusTags = const {},
  }) async {
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('hides when no data', (tester) async {
    const lesson = TheoryMiniLessonNode(id: 'l1', title: 'L1', content: '');
    final lib = _FakeLibrary(const [lesson]);
    await tester.pumpWidget(MaterialApp(
      home: TheoryLessonContextOverlay(
        lessonId: 'l1',
        library: lib,
        progress: MiniLessonProgressTracker.instance,
        review: _FakeReview(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('complete'), findsNothing);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('shows cluster progress', (tester) async {
    const l1 = TheoryMiniLessonNode(id: 'l1', title: 'L1', content: '');
    const l2 = TheoryMiniLessonNode(id: 'l2', title: 'L2', content: '');
    final cluster = TheoryLessonCluster(lessons: const [l1, l2], tags: const {});
    final lib = _FakeLibrary(const [l1, l2]);
    await MiniLessonProgressTracker.instance.markCompleted('l1');

    await tester.pumpWidget(MaterialApp(
      home: TheoryLessonContextOverlay(
        lessonId: 'l1',
        cluster: cluster,
        library: lib,
        progress: MiniLessonProgressTracker.instance,
        review: _FakeReview(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 complete'), findsOneWidget);
  });
}
