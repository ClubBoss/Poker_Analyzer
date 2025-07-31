import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/training_spot_v2.dart';

/// Loads training spots from built-in pack templates and indexes them by tag.
class TrainingSpotLibrary {
  final TrainingPackLibraryV2 library;

  TrainingSpotLibrary({TrainingPackLibraryV2? library})
      : library = library ?? TrainingPackLibraryV2.instance;

  bool _loaded = false;
  final List<TrainingSpotV2> _spots = [];
  final Map<String, List<TrainingSpotV2>> _index = {};

  Future<void> _load() async {
    if (_loaded) return;
    await library.loadFromFolder();
    for (final pack in library.packs) {
      final packTags = {for (final t in pack.tags) t.trim().toLowerCase()}
        ..removeWhere((e) => e.isEmpty);
      for (final spot in pack.spots) {
        final spotTags = {for (final t in spot.tags) t.trim().toLowerCase()}
          ..removeWhere((e) => e.isEmpty);
        final tags = {...packTags, ...spotTags};
        _spots.add(spot);
        for (final tag in tags) {
          _index.putIfAbsent(tag, () => []).add(spot);
        }
      }
    }
    _loaded = true;
  }

  /// Returns spots tagged with [tag].
  Future<List<TrainingSpotV2>> indexByTag(String tag) async {
    await _load();
    final key = tag.trim().toLowerCase();
    return List.unmodifiable(_index[key] ?? const []);
  }
}
