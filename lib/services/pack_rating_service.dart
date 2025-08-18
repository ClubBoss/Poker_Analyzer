import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PackRatingService {
  PackRatingService._();
  static final instance = PackRatingService._();

  static const _prefsKey = 'pack_ratings';
  Map<String, int> _ratings = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          _ratings = {
            for (final e in data.entries)
              e.key.toString(): (e.value as num).toInt(),
          };
        }
      } catch (_) {}
    }
  }

  Future<void> rate(String packId, int rating) async {
    if (rating < 1 || rating > 5) return;
    _ratings[packId] = rating;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_ratings));
  }

  Future<int?> getUserRating(String packId) async {
    return _ratings[packId];
  }

  Future<double?> getAverageRating(String packId) async {
    final r = _ratings[packId];
    return r?.toDouble();
  }
}
