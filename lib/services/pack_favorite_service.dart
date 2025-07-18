import 'package:shared_preferences/shared_preferences.dart';

class PackFavoriteService {
  PackFavoriteService._();
  static final instance = PackFavoriteService._();

  static const _prefsKey = 'pack_favorites';
  Set<String> _ids = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids = prefs.getStringList(_prefsKey)?.toSet() ?? {};
  }

  Future<void> toggleFavorite(String packId) async {
    if (!_ids.add(packId)) {
      _ids.remove(packId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _ids.toList());
  }

  bool isFavorite(String packId) => _ids.contains(packId);

  List<String> get allFavorites => List.unmodifiable(_ids);
}
