import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';
import 'training_pack_template_set_expander_service.dart';

/// Expands multiple [TrainingPackTemplateSet]s into a single list of
/// [TrainingPackSpot]s.
///
/// Each set is processed via [TrainingPackTemplateSetExpanderService].
/// Invalid sets are skipped, and the resulting spots preserve the order of the
/// input sets.
class TrainingPackTemplateMultiSetExpanderService {
  final TrainingPackTemplateSetExpanderService _expander;

  TrainingPackTemplateMultiSetExpanderService({
    TrainingPackTemplateSetExpanderService? expander,
  }) : _expander = expander ?? TrainingPackTemplateSetExpanderService();

  /// Expands all [sets] and returns the aggregated list of spots.
  ///
  /// If any set fails to expand, it is silently skipped.
  List<TrainingPackSpot> expandAll(List<TrainingPackTemplateSet> sets) {
    final results = <TrainingPackSpot>[];
    for (final set in sets) {
      try {
        results.addAll(_expander.expand(set));
      } catch (_) {
        // Ignore invalid sets
      }
    }
    return results;
  }
}
