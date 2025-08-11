import '../models/v2/training_pack_template_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'training_pack_template_storage_service.dart';

/// Registry resolving training packs by id from memory, assets or disk.
class PackRegistryService {
  PackRegistryService._();
  static final instance = PackRegistryService._();

  final Map<String, TrainingPackTemplateV2> _cache = {};
  bool _loaded = false;

  /// Registers [pack] in memory for subsequent lookups.
  void register(TrainingPackTemplateV2 pack) {
    _cache[pack.id] = pack;
  }

  /// Loads a pack by [id] checking memory cache, assets and disk cache.
  Future<TrainingPackTemplateV2?> getById(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;

    if (!_loaded) {
      _loaded = true;
      try {
        await TrainingPackLibraryV2.instance.loadFromFolder();
        for (final p in TrainingPackLibraryV2.instance.packs) {
          _cache[p.id] = p;
        }
      } catch (_) {}
    }
    final libPack = _cache[id] ?? TrainingPackLibraryV2.instance.getById(id);
    if (libPack != null) {
      _cache[id] = libPack;
      return libPack;
    }

    // Fallback to disk cache via storage service.
    try {
      final storage = TrainingPackTemplateStorageService();
      final tpl = await storage.loadById(id);
      if (tpl != null) {
        _cache[id] = tpl;
        return tpl;
      }
    } catch (_) {}
    return null;
  }
}

