import '../models/theory_mini_lesson_node.dart';
import '../models/training_pack_template_set.dart';
import '../models/training_pack_model.dart';
import 'training_pack_template_instance_expander_service.dart';

/// Generates [TheoryMiniLessonNode]s for packs produced from a
/// [TrainingPackTemplateSet].
///
/// Each generated lesson is linked to a single training pack and mirrors its
/// tags and relevant metadata such as `stage` or `targetStreet`.
class TheoryInjectorFromTemplateSetService {
  final TrainingPackTemplateInstanceExpanderService _expander;

  TheoryInjectorFromTemplateSetService({
    TrainingPackTemplateInstanceExpanderService? expander,
  }) : _expander = expander ?? TrainingPackTemplateInstanceExpanderService();

  /// Creates theory lessons corresponding to packs expanded from [set].
  ///
  /// [titlePrefix] is prepended to each lesson title. Additional parameters are
  /// forwarded to [TrainingPackTemplateInstanceExpanderService.expand] to ensure
  /// consistency with generated packs.
  List<TheoryMiniLessonNode> inject(
    TrainingPackTemplateSet set, {
    String titlePrefix = '',
    String? packIdPrefix,
    String? packTitle,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    final List<TrainingPackModel> packs = _expander.expand(
      set,
      packIdPrefix: packIdPrefix,
      title: packTitle,
      tags: tags,
      metadata: metadata,
    );

    final lessons = <TheoryMiniLessonNode>[];
    for (final pack in packs) {
      final stage = pack.metadata['stage']?.toString();
      final street = pack.metadata['targetStreet']?.toString() ??
          pack.metadata['street']?.toString();
      lessons.add(
        TheoryMiniLessonNode(
          id: 'theory_${pack.id}',
          title: '$titlePrefix${pack.title}',
          content: '',
          tags: List<String>.from(pack.tags),
          stage: stage,
          targetStreet: street,
          linkedPackIds: [pack.id],
        ),
      );
    }
    return lessons;
  }
}
