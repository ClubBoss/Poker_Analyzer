import '../models/training_pack_template_set.dart';
import '../models/constraint_set.dart';
import '../models/v2/training_pack_spot.dart';
import 'constraint_resolver_engine_v2.dart';

/// Expands a [TrainingPackTemplateSet] into concrete [TrainingPackSpot]s using
/// [ConstraintResolverEngine].
///
/// Each entry in [TrainingPackTemplateSet.variations] is treated as a
/// [ConstraintSet] describing property overrides and tag/metadata updates. The
/// resolver generates the cartesian product of all values within a variation and
/// applies them to the base spot, producing a unique spot for every combination.
class TrainingPackTemplateExpanderService {
  final ConstraintResolverEngine _engine;

  const TrainingPackTemplateExpanderService({ConstraintResolverEngine? engine})
      : _engine = engine ?? const ConstraintResolverEngine();

  /// Generates all spots described by [set].
  List<TrainingPackSpot> expand(TrainingPackTemplateSet set) {
    final sets = [
      for (final v in set.variations) ConstraintSet(overrides: v),
    ];
    return _engine.apply(set.baseSpot, sets);
  }
}
