import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import 'auto_deduplication_engine.dart';

/// Imports template data while avoiding duplicate spots.
class TrainingPackTemplateImporter {
  final AutoDeduplicationEngine _dedup;

  TrainingPackTemplateImporter({AutoDeduplicationEngine? dedup})
      : _dedup = dedup ?? AutoDeduplicationEngine();

  /// Merges [incoming] into [base], skipping any spots already present.
  TrainingPackTemplateV2 merge(
    TrainingPackTemplateV2 base,
    TrainingPackTemplateV2 incoming,
  ) {
    _dedup.addExisting(base.spots);
    final merged = <TrainingPackSpot>[];
    for (final spot in incoming.spots) {
      if (_dedup.isDuplicate(spot, source: incoming.id)) continue;
      merged.add(spot);
    }
    base.spots.addAll(merged);
    base.spotCount = base.spots.length;
    return base;
  }
}
