import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists IDs of practice spots from the last completed session.
class RecentSpotHistoryService {
  RecentSpotHistoryService._();
  static final RecentSpotHistoryService instance = RecentSpotHistoryService._();

  static const _prefsKey = 'recent_spot_history';

  /// Returns stored spot IDs from the last session.
  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return <String>[];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return [
          for (final id in data)
            if (id is String) id
        ];
      }
    } catch (_) {}
    return <String>[];
  }

  /// Stores [spotIds] as the most recent session history.
  Future<void> save(List<String> spotIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(spotIds));
  }
}
