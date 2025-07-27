import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'package:collection/collection.dart';

class PackLibraryService {
  PackLibraryService._();
  static final instance = PackLibraryService._();

  Future<TrainingPackTemplateV2?> recommendedStarter() async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final list = TrainingPackLibraryV2.instance.filterBy(type: TrainingType.pushFold);
    for (final p in list) {
      if (p.tags.contains('starter')) return p;
    }
    return list.isNotEmpty ? list.first : null;
  }

  /// Loads a template by [id] from the library.
  Future<TrainingPackTemplateV2?> getById(String id) async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    return TrainingPackLibraryV2.instance.getById(id);
  }

  /// Returns the first pack containing [tag] or `null` if none found.
  Future<TrainingPackTemplateV2?> findByTag(String tag) async {
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final list = TrainingPackLibraryV2.instance.filterBy(type: TrainingType.pushFold);
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
