import '../models/training_pack_template_set.dart';
import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_spot.dart';
import 'training_pack_generator_engine_v2.dart';
import 'auto_deduplication_engine.dart';

/// Wrapper around [TrainingPackGeneratorEngineV2] that skips duplicate spots.
class TrainingPackAutoGenerator {
  final TrainingPackGeneratorEngineV2 _engine;
  final AutoDeduplicationEngine _dedup;

  TrainingPackAutoGenerator({
    TrainingPackGeneratorEngineV2? engine,
    AutoDeduplicationEngine? dedup,
  })  : _engine = engine ?? TrainingPackGeneratorEngineV2(),
        _dedup = dedup ?? AutoDeduplicationEngine();

  /// Generates spots from [set] while skipping duplicates based on fingerprints.
  List<TrainingPackSpot> generate(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
    Iterable<TrainingPackSpot> existingSpots = const [],
  }) {
    _dedup.addExisting(existingSpots);
    final spots = _engine.generate(set, theoryIndex: theoryIndex);
    final filtered = <TrainingPackSpot>[];
    for (final spot in spots) {
      if (_dedup.isDuplicate(spot, source: 'auto')) continue;
      filtered.add(spot);
    }
    return filtered;
  }
}
