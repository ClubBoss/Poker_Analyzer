import '../models/v2/training_pack_template_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'training_pack_library_loader_service.dart';

class BoosterLibraryService {
  BoosterLibraryService._();
  static final BoosterLibraryService instance = BoosterLibraryService._();

  final List<TrainingPackTemplateV2> _boosters = [];
  final Map<String, TrainingPackTemplateV2> _index = {};
  bool _loaded = false;

  Future<void> loadAll({int limit = 500}) async {
    if (_loaded) return;
    await TrainingPackLibraryLoaderService.instance.preloadLibrary(
      limit: limit,
    );
    final all = TrainingPackLibraryLoaderService.instance.loadedTemplates;
    _boosters.clear();
    _index.clear();
    for (final tpl in all) {
      final meta = tpl.meta;
      if (meta['type']?.toString().toLowerCase() == 'booster') {
        _boosters.add(tpl);
        _index[tpl.id] = tpl;
      }
    }
    // Fallback to bundled packs
    if (_boosters.isEmpty) {
      await TrainingPackLibraryV2.instance.loadFromFolder();
      final packs = TrainingPackLibraryV2.instance.filterBy(
        type: TrainingType.pushFold,
      );
      for (final p in packs) {
        final meta = p.meta;
        if (meta['type']?.toString().toLowerCase() == 'booster') {
          _boosters.add(p);
          _index[p.id] = p;
        }
      }
    }
    _loaded = true;
  }

  List<TrainingPackTemplateV2> get all => List.unmodifiable(_boosters);

  TrainingPackTemplateV2? getById(String id) => _index[id];

  List<TrainingPackTemplateV2> findByTag(String tag) {
    final lc = tag.toLowerCase();
    return [
      for (final p in _boosters)
        if (p.meta['tag']?.toString().toLowerCase() == lc) p,
    ];
  }
}
