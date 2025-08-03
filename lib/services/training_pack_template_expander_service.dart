import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';
import 'constraint_resolver_engine_v2.dart';
import 'auto_spot_theory_injector_service.dart';

/// Expands a [TrainingPackTemplateSet] into concrete [TrainingPackSpot]s using
/// [ConstraintResolverEngine].
///
/// Each entry in [TrainingPackTemplateSet.variations] is treated as a
/// [ConstraintSet] describing property overrides and tag/metadata updates. The
/// resolver generates the cartesian product of all values within a variation and
/// applies them to the base spot, producing a unique spot for every combination.
class TrainingPackTemplateExpanderService {
  final ConstraintResolverEngine _engine;
  final AutoSpotTheoryInjectorService _injector;

  TrainingPackTemplateExpanderService({
    ConstraintResolverEngine? engine,
    AutoSpotTheoryInjectorService? injector,
  })  : _engine = engine ?? const ConstraintResolverEngine(),
        _injector = injector ?? AutoSpotTheoryInjectorService();

  /// Generates all spots described by [set] and injects theory links.
  List<TrainingPackSpot> expand(TrainingPackTemplateSet set) {
    final spots = _engine.apply(set.baseSpot, set.variations);
    _injector.injectAll(spots);
    return spots;
  }
}
