import 'constraint_set.dart';
import 'spot_seed_format.dart';

/// Defines a base spot template and a list of variant constraints that
/// can be expanded into multiple [SpotSeedFormat] instances.
class TrainingPackTemplateSet {
  final SpotSeedFormat baseTemplate;
  final List<ConstraintSet> variants;

  const TrainingPackTemplateSet({
    required this.baseTemplate,
    required this.variants,
  });
}
