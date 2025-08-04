import '../models/skill_tree_node_model.dart';
import '../services/skill_node_decay_review_injector.dart';
import '../services/inline_theory_linker_service.dart';
import '../services/pack_library_service.dart';
import '../models/v2/training_pack_template_v2.dart';

/// Groups [LearningPathEntry] items for a [SkillTreeNodeModel] into
/// logical learning stages (review -> theory -> practice).
class LearningPathEntryGroupBuilder {
  final SkillNodeDecayReviewInjector decayInjector;
  final InlineTheoryLinkerService linker;
  final PackLibraryService packLibrary;

  LearningPathEntryGroupBuilder({
    SkillNodeDecayReviewInjector? decayInjector,
    InlineTheoryLinkerService? linker,
    PackLibraryService? packLibrary,
  }) : decayInjector = decayInjector ?? SkillNodeDecayReviewInjector(),
       linker = linker ?? InlineTheoryLinkerService(),
       packLibrary = packLibrary ?? PackLibraryService.instance;

  /// Returns ordered groups of learning path entries for [node].
  Future<List<LearningPathEntryGroup>> build(SkillTreeNodeModel node) async {
    final groups = <LearningPathEntryGroup>[];

    final review = await decayInjector.injectDecayReviews(node);
    if (review.isNotEmpty) {
      groups.add(LearningPathEntryGroup(title: 'Review', entries: review));
    }

    final TrainingPackTemplateV2? pack = await packLibrary.getById(
      node.trainingPackId,
    );

    final theory = pack != null
        ? await linker.extractRelevantLessons(pack.tags)
        : [];
    if (theory.isNotEmpty) {
      groups.add(LearningPathEntryGroup(title: 'Theory', entries: theory));
    }

    if (pack != null) {
      groups.add(LearningPathEntryGroup(title: 'Practice', entries: [pack]));
    }

    return groups;
  }
}

/// Container for grouped learning path entries.
class LearningPathEntryGroup {
  final String title;
  final List<LearningPathEntry> entries;

  const LearningPathEntryGroup({required this.title, required this.entries});
}
