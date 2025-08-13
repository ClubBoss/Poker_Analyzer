import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../generated/pack_library.g.dart';
import 'package:collection/collection.dart';

class PackLibraryService {
  PackLibraryService._();
  static final instance = PackLibraryService._();

  int count() => packLibrary.length;

  void addOrUpdate(TrainingPackTemplateV2 template) {
    packLibrary[template.id] = List<TrainingPackSpot>.from(template.spots);
  }

  /// Returns spots for the pack identified by [id].
  ///
  /// If the [id] is unknown, an empty list is returned.
  List<TrainingPackSpot> getPack(String id) {
    final spots = packLibrary[id];
    return spots == null
        ? const []
        : List<TrainingPackSpot>.unmodifiable(spots);
  }

  /// Lists all pack ids available in the precompiled [packLibrary].
  List<String> getAvailablePackIds() {
    return List<String>.unmodifiable(packLibrary.keys);
  }

  Future<List<TrainingPackTemplateV2>> listStarters() async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final list =
        TrainingPackLibraryV2.instance.filterBy(type: TrainingType.pushFold);
    return list.where((p) => p.tags.contains('starter')).toList();
  }

  Future<TrainingPackTemplateV2?> recommendedStarter() async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final list =
        TrainingPackLibraryV2.instance.filterBy(type: TrainingType.pushFold);
    if (list.isEmpty) return null;

    final starters = list.where((p) => p.tags.contains('starter')).toList();
    if (starters.isEmpty) return list.first;
    starters.sort((a, b) => b.spotCount.compareTo(a.spotCount));
    return starters.first;
  }

  /// Loads a template by [id] from the library.
  Future<TrainingPackTemplateV2?> getById(String id) async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    return TrainingPackLibraryV2.instance.getById(id);
  }

  /// Returns the first pack containing [tag] or `null` if none found.
  Future<TrainingPackTemplateV2?> findByTag(String tag) async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final list =
        TrainingPackLibraryV2.instance.filterBy(type: TrainingType.pushFold);
    return list.firstWhereOrNull((p) => p.tags.contains(tag));
  }

  /// Returns ids of booster packs matching [tag].
  Future<List<String>> findBoosterCandidates(String tag) async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final lc = tag.toLowerCase();
    final list = TrainingPackLibraryV2.instance.filterBy(
      type: TrainingType.pushFold,
    );
    final ids = <String>[];
    for (final p in list) {
      final meta = p.meta;
      if (meta['type']?.toString().toLowerCase() == 'booster' &&
          meta['tag']?.toString().toLowerCase() == lc) {
        ids.add(p.id);
      }
    }
    return ids;
  }
}
