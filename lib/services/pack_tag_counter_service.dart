import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack_model.dart';

/// Tracks how often each tag appears in generated training packs.
///
/// Counts are persisted locally using [SharedPreferences]. Tags are stored in
/// lowercase to ensure consistent aggregation.
class PackTagCounterService {
  PackTagCounterService._();

  /// Singleton instance of the service.
  static final PackTagCounterService instance = PackTagCounterService._();

  static const _prefsKey = 'pack_tag_counts';

  final Map<String, int> _counts = <String, int>{};
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          for (final entry in data.entries) {
            final key = entry.key.toString().toLowerCase();
            final value = entry.value;
            final count = value is int ? value : int.tryParse(value.toString());
            if (count != null) _counts[key] = count;
          }
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  /// Logs [pack], incrementing counts for each of its tags.
  void logPack(TrainingPackModel pack) {
    unawaited(_logPack(pack));
  }

  Future<void> _logPack(TrainingPackModel pack) async {
    await _load();
    for (final tag in pack.tags) {
      final t = tag.toLowerCase();
      _counts[t] = (_counts[t] ?? 0) + 1;
    }
    await _save();
  }

  /// Returns a copy of the current tag counts.
  Map<String, int> getTagCounts() => Map<String, int>.from(_counts);

  /// Clears all stored counts.
  void reset() {
    _counts.clear();
    unawaited(_clearPrefs());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_counts));
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
