import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_lesson_cluster_linker_service.dart';
import 'package:poker_analyzer/services/theory_lesson_navigator_service.dart';
import 'package:poker_analyzer/services/theory_suggestion_engagement_tracker_service.dart';
import 'package:poker_analyzer/models/theory_suggestion_engagement_event.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];

  @override
  List<String> linkedPacksFor(String lessonId) => const [];
}

class _FakeTracker implements TheorySuggestionEngagementTrackerService {
  @override
  Future<void> lessonSuggested(String lessonId) async {}

  @override
  Future<void> lessonExpanded(String lessonId) async {}

  @override
  Future<void> lessonOpened(String lessonId) async {}

  @override
  Future<Map<String, int>> countByAction(String action) async => const {};

  @override
  Future<List<TheorySuggestionEngagementEvent>> eventsByAction(String action) async =>
      const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('navigates within cluster alphabetically', () async {
    final lessons = [
      TheoryMiniLessonNode(id: 'a', title: 'Alpha', content: '', tags: const ['x']),
      TheoryMiniLessonNode(id: 'b', title: 'Beta', content: '', tags: const ['x']),
      TheoryMiniLessonNode(id: 'c', title: 'Gamma', content: '', tags: const ['x']),
      TheoryMiniLessonNode(id: 'd', title: 'Delta', content: '', tags: const ['y']),
    ];
    final linker = TheoryLessonClusterLinkerService(
      library: _FakeLibrary(lessons),
      tracker: _FakeTracker(),
    );
    final nav = TheoryLessonNavigatorService(linker: linker);

    expect(await nav.getNextLessonId('a'), 'b');
    expect(await nav.getPreviousLessonId('a'), isNull);
    expect(await nav.getNextLessonId('b'), 'c');
    expect(await nav.getPreviousLessonId('c'), 'b');
    expect(await nav.getNextLessonId('c'), isNull);
    expect(await nav.getNextLessonId('d'), isNull);
  });
}
