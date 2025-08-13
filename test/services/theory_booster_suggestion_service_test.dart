import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/theory_booster_suggestion_service.dart';
import 'package:poker_analyzer/services/theory_mini_lesson_linker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import "package:poker_analyzer/services/pack_library_loader_service.dart";
import "package:poker_analyzer/models/v2/training_pack_template_v2.dart";

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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

class _FakeLinker extends TheoryMiniLessonLinker {
  _FakeLinker({required MiniLessonLibraryService library})
      : super(library: library, loader: _FakeLoader());
}

class _FakeLoader implements PackLibraryLoaderService {
  @override
  Future<List<TrainingPackTemplateV2>> loadLibrary() async => const [];

  @override
  List<TrainingPackTemplateV2> get library => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MiniLessonProgressTracker.instance.onLessonCompleted.listen((_) {});
  });

  test('suggestForSpot returns lessons matching tags and stage', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'A',
        content: '',
        tags: ['level2', 'openfold'],
        stage: 'level2',
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'B',
        content: '',
        tags: ['level2', '3bet-push'],
        stage: 'level2',
      ),
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'C',
        content: '',
        tags: ['level1', 'openfold'],
        stage: 'level1',
      ),
    ];
    final library = _FakeLibrary(lessons);
    final linker = _FakeLinker(library: library);

    await MiniLessonProgressTracker.instance.markCompleted('l2');

    final spot = TrainingPackSpot(
        id: 's1', hand: HandData(), tags: ['level2', 'openfold']);

    final service = TheoryBoosterSuggestionService(
      linker: linker,
      library: library,
      progress: MiniLessonProgressTracker.instance,
    );

    final result = await service.suggestForSpot(spot);
    expect(result.map((e) => e.id), ['l1']);
  });
}
