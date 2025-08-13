import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/inline_theory_linking/postflop_jam_decision_theory_linker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';

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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => lessons;

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => lessons;
}

void main() {
  test('links jam decision packs', () async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'River Jam Decisions',
      content: '',
      tags: ['river', 'jam', 'decision'],
    );
    final library = _FakeLibrary([lesson]);
    final linker = PostflopJamDecisionTheoryLinker(library: library);
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack',
      trainingType: TrainingType.postflop,
      tags: ['jamDecision'],
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      spotCount: 1,
      meta: {},
    );

    await linker.link([pack]);

    expect(pack.spots.first.meta['theoryRef'], {
      'lessonId': 'l1',
      'title': 'River Jam Decisions',
    });
  });

  test('ignores packs without jam tag', () async {
    const lesson = TheoryMiniLessonNode(
      id: 'l1',
      title: 'River Jam Decisions',
      content: '',
      tags: ['river', 'jam', 'decision'],
    );
    final library = _FakeLibrary([lesson]);
    final linker = PostflopJamDecisionTheoryLinker(library: library);
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack',
      trainingType: TrainingType.postflop,
      tags: [],
      spots: [TrainingPackSpot(id: 's1', hand: HandData())],
      spotCount: 1,
      meta: {},
    );

    await linker.link([pack]);

    expect(pack.spots.first.meta.containsKey('theoryRef'), false);
  });
}
