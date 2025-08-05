import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/theory_suggestion_engagement_event.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_lesson_cluster_linker_service.dart';
import 'package:poker_analyzer/services/theory_suggestion_engagement_tracker_service.dart';

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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) =>
      [for (final t in tags) ...lessons.where((l) => l.tags.contains(t))];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => findByTags(tags.toList());

  @override
  List<String> linkedPacksFor(String lessonId) =>
      getById(lessonId)?.linkedPackIds ?? const [];
}

class _FakeTracker implements TheorySuggestionEngagementTrackerService {
  final List<TheorySuggestionEngagementEvent> events;
  _FakeTracker(this.events);

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
      events.where((e) => e.action == action).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clusters lessons by tags, packs and co-suggestions', () async {
    final lessons = [
      TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: const ['x'],
        linkedPackIds: const ['p1'],
      ),
      TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: '',
        tags: const ['x'],
      ),
      TheoryMiniLessonNode(
        id: 'l3',
        title: 'L3',
        content: '',
        tags: const ['y'],
        linkedPackIds: const ['p1'],
      ),
      TheoryMiniLessonNode(
        id: 'l4',
        title: 'L4',
        content: '',
        tags: const ['z'],
      ),
      TheoryMiniLessonNode(
        id: 'l5',
        title: 'L5',
        content: '',
        tags: const ['w'],
      ),
    ];

    final now = DateTime(2023, 1, 1);
    final events = <TheorySuggestionEngagementEvent>[];
    for (var i = 0; i < 3; i++) {
      final t = now.add(Duration(minutes: i));
      events.add(TheorySuggestionEngagementEvent(
          lessonId: 'l4', action: 'suggested', timestamp: t));
      events.add(TheorySuggestionEngagementEvent(
          lessonId: 'l5', action: 'suggested', timestamp: t));
    }

    final library = _FakeLibrary(lessons);
    final tracker = _FakeTracker(events);
    final service = TheoryLessonClusterLinkerService(
      library: library,
      tracker: tracker,
    );

    final clusters = await service.clusters();
    expect(clusters.length, 2);

    final idsCluster1 = clusters[0].lessons.map((e) => e.id).toSet();
    final idsCluster2 = clusters[1].lessons.map((e) => e.id).toSet();

    expect(idsCluster1, containsAll(['l1', 'l2', 'l3']));
    expect(idsCluster2, containsAll(['l4', 'l5']));

    final cluster = await service.getCluster('l5');
    expect(cluster, isNotNull);
    expect(cluster!.lessons.map((e) => e.id).toSet(), {'l4', 'l5'});
  });
}
