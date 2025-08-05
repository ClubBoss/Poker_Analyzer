import '../models/training_pack_model.dart';
import '../models/training_pack_template_set_group.dart';
import 'training_pack_template_multi_set_expander_service.dart';

class TrainingPackLibraryGenerator {
  final TrainingPackTemplateMultiSetExpanderService _expander;
  final List<String> errors = [];

  TrainingPackLibraryGenerator({
    TrainingPackTemplateMultiSetExpanderService? expander,
  }) : _expander = expander ?? TrainingPackTemplateMultiSetExpanderService();

  List<TrainingPackModel> generate(List<TrainingPackTemplateSetGroup> groups) {
    final packs = <TrainingPackModel>[];
    for (final g in groups) {
      try {
        final spots = _expander.expandAll(g.sets);
        if (spots.isEmpty) {
          errors.add('Pack ${g.packId} is empty');
          continue;
        }
        packs.add(
          TrainingPackModel(
            id: g.packId,
            title: g.title,
            spots: spots,
            tags: g.tags,
          ),
        );
      } catch (e) {
        errors.add('Pack ${g.packId} failed: $e');
      }
    }
    return packs;
  }
}
