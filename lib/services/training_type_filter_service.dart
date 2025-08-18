import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';

class TrainingTypeFilterService {
  static List<TrainingPackTemplateV2> filterByType(
    List<TrainingPackTemplateV2> packs,
    Set<TrainingType> allowedTypes,
  ) {
    if (allowedTypes.isEmpty) return List<TrainingPackTemplateV2>.from(packs);
    return [
      for (final p in packs)
        if (allowedTypes.contains(p.trainingType)) p,
    ];
  }
}
