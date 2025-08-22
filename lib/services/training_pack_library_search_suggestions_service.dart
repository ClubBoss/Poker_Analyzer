import '../models/training_pack_meta.dart';
import 'training_pack_index_service.dart';

/// Provides search suggestions based on available training packs.
class TrainingPackLibrarySearchSuggestionsService {
  final TrainingPackIndexService _indexService;

  TrainingPackLibrarySearchSuggestionsService({
    TrainingPackIndexService? indexService,
  }) : _indexService = indexService ?? TrainingPackIndexService.instance;

  /// Returns tags ordered by popularity across all packs.
  List<String> getSuggestedTags({int limit = 5}) {
    final counts = <String, int>{};
    for (final pack in _indexService.getAll()) {
      for (final tag in pack.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });
    return sorted.map((e) => e.key).take(limit).toList();
  }

  /// Returns starter packs intended for onboarding.
  List<TrainingPackMeta> getSuggestedStarterPacks() {
    final packs = _indexService
        .getAll()
        .where((p) => p.tags.contains('starter'))
        .toList();
    packs.sort((a, b) => a.title.compareTo(b.title));
    return packs;
  }
}
