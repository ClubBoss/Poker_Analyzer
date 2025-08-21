import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_linker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/pack_library_loader_service.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [
    for (final t in tags) ...lessons.where((l) => l.tags.contains(t)),
  ];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

class _FakeLoader implements PackLibraryLoaderService {
  final List<TrainingPackTemplateV2> packs;
  _FakeLoader(this.packs);

  @override
  Future<List<TrainingPackTemplateV2>> loadLibrary() async => packs;

  @override
  List<TrainingPackTemplateV2> get library => packs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('linker maps lessons to packs by tags and stage', () async {
    final lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'L1',
      content: '',
      stage: 'level2',
      tags: const ['level2', '3bet-push'],
    );
    final packs = [
      TrainingPackTemplateV2(
        id: 'p1',
        name: 'P1',
        trainingType: TrainingType.pushFold,
        tags: ['level2', '3bet-push'],
        meta: {'stage': 'level2'},
      ),
      TrainingPackTemplateV2(
        id: 'p2',
        name: 'P2',
        trainingType: TrainingType.pushFold,
        tags: ['level1', '3bet-push'],
        meta: {'stage': 'level1'},
      ),
    ];
    final library = _FakeLibrary([lesson]);
    final loader = _FakeLoader(packs);
    final linker = TheoryMiniLessonLinker(library: library, loader: loader);

    await linker.link(force: true);

    expect(lesson.linkedPackIds, equals(['p1']));
  });
}
