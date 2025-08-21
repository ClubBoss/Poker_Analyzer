import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_node.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/services/effective_theory_injector_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_lesson_effectiveness_analyzer_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);
  @override
  List<TheoryMiniLessonNode> get all => items;
  @override
  TheoryMiniLessonNode? getById(String id) {
    for (final l in items) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) =>
      items.where((e) => e.tags.any(tags.contains)).toList();
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
  @override
  List<String> linkedPacksFor(String lessonId) => const [];
}

class _FakeAnalyzer extends TheoryLessonEffectivenessAnalyzerService {
  final Map<String, double> gains;
  _FakeAnalyzer(this.gains)
      : super(retention: DecayTagRetentionTrackerService());
  @override
  Future<Map<String, double>> getTopEffectiveLessons({
    int minSessions = 3,
  }) async =>
      gains;
}

class _FakeRetention extends DecayTagRetentionTrackerService {
  final List<MapEntry<String, double>> tags;
  const _FakeRetention(this.tags) : super();
  @override
  Future<List<MapEntry<String, double>>> getMostDecayedTags(
    int limit, {
    DateTime? now,
  }) async {
    final list = List<MapEntry<String, double>>.from(tags);
    list.sort((a, b) => b.value.compareTo(a.value));
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lesson1 = TheoryMiniLessonNode(
    id: 'l1',
    title: 'L1',
    content: '',
    tags: const ['icm'],
    nextIds: const [],
  );
  final lesson2 = TheoryMiniLessonNode(
    id: 'l2',
    title: 'L2',
    content: '',
    tags: const ['icm'],
    nextIds: const [],
  );

  test('getInjectableLessonsForTag ranks by gain', () async {
    final library = _FakeLibrary([lesson1, lesson2]);
    final analyzer = _FakeAnalyzer({'l1': 5.0, 'l2': 2.0});
    final service = EffectiveTheoryInjectorService(
      analyzer: analyzer,
      library: library,
      retention: DecayTagRetentionTrackerService(),
    );

    final result = await service.getInjectableLessonsForTag('icm');
    expect(result.length, 2);
    expect(result.first.id, 'l1');
    expect(result.last.id, 'l2');
    expect(result.first, isA<TheoryLessonNode>());
  });

  test('getTopTheoryBoosters returns map of tags to lessons', () async {
    final library = _FakeLibrary([lesson1]);
    final analyzer = _FakeAnalyzer({'l1': 4.0});
    final retention = _FakeRetention([
      const MapEntry('icm', 0.9),
      const MapEntry('math', 0.8),
    ]);
    final service = EffectiveTheoryInjectorService(
      analyzer: analyzer,
      library: library,
      retention: retention,
    );
    final map = await service.getTopTheoryBoosters(limit: 2);
    expect(map.length, 1);
    expect(map.containsKey('icm'), isTrue);
    expect(map['icm']!.first.id, 'l1');
  });
}
