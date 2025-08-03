import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


/// Persists tag mastery values between app sessions.
class MasteryPersistenceService {
  static const _key = 'tag_mastery';

  /// Saves the provided [tagMastery] map to local storage.
  Future<void> save(Map<String, double> tagMastery) async {
    final prefs = await PreferencesService.getInstance();
    final sanitized = <String, double>{};
    tagMastery.forEach((tag, value) {
      final key = tag.trim().toLowerCase();
      if (key.isEmpty) return;
      if (value.isNaN || value.isInfinite) return;
      sanitized[key] = value.clamp(0.0, 1.0);
    });
    await prefs.setString(_key, jsonEncode(sanitized));
  }

  /// Loads the persisted tag mastery map.
  Future<Map<String, double>> load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        final result = <String, double>{};
        for (final entry in data.entries) {
          final key = entry.key.toString().trim().toLowerCase();
          if (key.isEmpty) continue;
          final value = entry.value;
          double? v;
          if (value is num) {
            v = value.toDouble();
          } else if (value is String) {
            v = double.tryParse(value);
          }
          if (v != null && v.isFinite) {
            result[key] = v.clamp(0.0, 1.0);
          }
        }
        return result;
      }
    } catch (_) {}
    return {};
  }
}
