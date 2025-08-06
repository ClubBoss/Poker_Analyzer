import '../models/training_pack_template_set.dart';
import '../models/inline_theory_entry.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import 'training_pack_generator_engine_v2.dart';
import 'auto_deduplication_engine.dart';

/// Wrapper around [TrainingPackGeneratorEngineV2] that skips duplicate spots.
class TrainingPackAutoGenerator {
  final TrainingPackGeneratorEngineV2 _engine;
  final AutoDeduplicationEngine _dedup;
  bool _shouldAbort = false;

  TrainingPackAutoGenerator({
    TrainingPackGeneratorEngineV2? engine,
    AutoDeduplicationEngine? dedup,
  })  : _engine = engine ?? TrainingPackGeneratorEngineV2(),
        _dedup = dedup ?? AutoDeduplicationEngine();

  /// Generates spots from [set] and optionally deduplicates them based on
  /// fingerprints.
  List<TrainingPackSpot> generate(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
    Iterable<TrainingPackSpot> existingSpots = const [],
    bool deduplicate = true,
  }) {
    if (_shouldAbort) return [];
    if (deduplicate) {
      _dedup.addExisting(existingSpots);
    }
    final spots = _engine.generate(set, theoryIndex: theoryIndex);
    if (_shouldAbort || !deduplicate) return spots;

    final pack = TrainingPackModel(
      id: set.baseSpot.id,
      title: set.baseSpot.title,
      spots: spots,
    );
    final filtered = _dedup.deduplicate(pack);
    return filtered.spots;
  }

  /// Requests the generator to stop processing.
  void abort() {
    _shouldAbort = true;
  }

  /// Whether an abort has been requested.
  bool get shouldAbort => _shouldAbort;
}
