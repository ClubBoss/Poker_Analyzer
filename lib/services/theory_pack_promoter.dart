import '../models/pack_library.dart';
import '../models/v2/training_pack_template_v2.dart';

/// Moves validated theory packs from [PackLibrary.staging] into
/// [PackLibrary.main].
class TheoryPackPromoter {
  TheoryPackPromoter();

  /// Copies all packs from [PackLibrary.staging] to [PackLibrary.main].
  /// Existing IDs in the main library are skipped. Each promoted pack gets
  /// `meta['source'] = 'theory_promoted'` and `meta['category'] = [category]`.
  /// The original entry is removed from the staging library.
  int promoteAll(String category) {
    final list = List<TrainingPackTemplateV2>.from(PackLibrary.staging.packs);
    var count = 0;
    for (final tpl in list) {
      if (PackLibrary.main.getById(tpl.id) != null) {
        continue;
      }
      tpl.meta = Map<String, dynamic>.from(tpl.meta)
        ..['source'] = 'theory_promoted'
        ..['category'] = category;
      PackLibrary.main.add(tpl);
      PackLibrary.staging.remove(tpl.id);
      count++;
    }
    return count;
  }
}
