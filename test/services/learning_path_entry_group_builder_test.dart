import 'package:test/test.dart';
import 'package:poker_analyzer/services/learning_path_entry_group_builder.dart';
import 'package:poker_analyzer/services/skill_node_decay_review_injector.dart';
import 'package:poker_analyzer/services/inline_theory_linker_service.dart';
import 'package:poker_analyzer/services/pack_library_service.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';

class _FakeDecayInjector extends SkillNodeDecayReviewInjector {
  @override
  Future<List<LearningPathEntry>> injectDecayReviews(
    SkillTreeNodeModel node, {
    double thresholdDays = 30,
  }) async {
    return ['review'];
  }
}

class _FakeTheoryLinker extends InlineTheoryLinkerService {
  @override
  Future<List<TheoryMiniLessonNode>> extractRelevantLessons(
    List<String> tags,
  ) async {
    return [const TheoryMiniLessonNode(id: 't1', title: 'Lesson', content: '')];
  }
}

class _FakePackLibraryService implements PackLibraryService {
  final TrainingPackTemplateV2 pack;

  _FakePackLibraryService(this.pack);

  @override
  Future<TrainingPackTemplateV2?> getById(String id) async => pack;

  @override
  List<TrainingPackSpot> getPack(String id) => const [];

  @override
  List<String> getAvailablePackIds() => const [];

  @override
  Future<TrainingPackTemplateV2?> recommendedStarter() async => null;

  @override
  Future<TrainingPackTemplateV2?> findByTag(String tag) async => null;

  @override
  Future<List<String>> findBoosterCandidates(String tag) async => const [];
}

void main() {
  test('builds groups in expected order', () async {
    const node = SkillTreeNodeModel(
      id: 'n1',
      title: 'Node',
      category: 'cat',
      trainingPackId: 'pack',
    );
    const pack = TrainingPackTemplateV2(
      id: 'pack',
      name: 'Practice',
      trainingType: TrainingType.pushFold,
      tags: ['tag1'],
    );
    final builder = LearningPathEntryGroupBuilder(
      decayInjector: _FakeDecayInjector(),
      linker: _FakeTheoryLinker(),
      packLibrary: _FakePackLibraryService(pack),
    );

    final groups = await builder.build(node);

    expect(groups.length, 3);
    expect(groups[0].title, 'Review');
    expect(groups[1].title, 'Theory');
    expect(groups[2].title, 'Practice');
    expect(groups[2].entries.first, pack);
  });
}
