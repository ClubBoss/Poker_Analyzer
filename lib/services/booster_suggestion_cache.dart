import 'package:shared_preferences/shared_preferences.dart';

import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/training_pack_template_v2.dart';

/// Handles caching of booster suggestions to avoid recomputation.
class BoosterSuggestionCache {
  static const _cacheKey = 'smart_booster_cache';
  static const _cacheTimeKey = 'smart_booster_cache_time';

  const BoosterSuggestionCache();

  /// Returns the cached booster pack if it was saved within 24 hours.
  Future<TrainingPackTemplateV2?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTimeStr = prefs.getString(_cacheTimeKey);
    final cacheId = prefs.getString(_cacheKey);
    if (cacheTimeStr == null || cacheId == null) return null;
    final ts = DateTime.tryParse(cacheTimeStr);
    if (ts == null ||
        DateTime.now().difference(ts) >= const Duration(hours: 24)) {
      return null;
    }
    await TrainingPackLibraryV2.instance.loadFromFolder();
    return TrainingPackLibraryV2.instance.getById(cacheId);
  }

  /// Saves [tpl] to the cache with current timestamp.
  Future<void> save(TrainingPackTemplateV2 tpl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, tpl.id);
    await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
  }
}
