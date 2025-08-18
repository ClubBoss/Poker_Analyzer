import '../models/learning_path_stage_model.dart';
import '../models/stage_type.dart';
import '../models/theory_pack_model.dart';
import 'theory_pack_auto_tagger.dart';
import 'theory_pack_auto_booster_suggester.dart';

/// Converts theory packs into [LearningPathStageModel] entries.
class TheoryPackStageInjector {
  final TheoryPackAutoTagger tagger;
  final TheoryPackAutoBoosterSuggester boosterSuggester;
  final List<TheoryPackModel> boosterLibrary;

  const TheoryPackStageInjector({
    this.tagger = const TheoryPackAutoTagger(),
    this.boosterSuggester = const TheoryPackAutoBoosterSuggester(),
    this.boosterLibrary = const [],
  });

  /// Builds a learning path stage from [pack].
  ///
  /// The resulting stage references [pack] as a theory stage and
  /// auto-detects tags and boosters for smart progression.
  LearningPathStageModel injectFromTheoryPack(TheoryPackModel pack) {
    final tags = <String>{
      ...pack.tags.map((e) => e.trim()),
      ...tagger.autoTag(pack).map((e) => e.trim()),
    }..removeWhere((e) => e.isEmpty);
    final tagList = tags.toList()..sort();

    final boosters = boosterLibrary.isEmpty
        ? <String>[]
        : boosterSuggester.suggestBoosters(pack, boosterLibrary);

    final description = pack.sections.isNotEmpty
        ? pack.sections.first.text
        : '';
    final stageId = pack.id.endsWith('_stage') ? pack.id : '${pack.id}_stage';

    return LearningPathStageModel(
      id: stageId,
      title: pack.title,
      description: description,
      packId: pack.id,
      theoryPackId: pack.id,
      boosterTheoryPackIds: boosters.isEmpty ? null : boosters,
      requiredAccuracy: 0,
      minHands: 0,
      tags: tagList,
      type: StageType.theory,
    );
  }
}
