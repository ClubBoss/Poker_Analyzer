import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'suggestion_cooldown_manager.dart';

class SuggestedPackRecord {
  final String packId;
  final String source;
  final DateTime timestamp;
  final String? tagContext;

  SuggestedPackRecord({
    required this.packId,
    required this.source,
    required this.timestamp,
    this.tagContext,
  });

  Map<String, dynamic> toJson() => {
        'id': packId,
        'source': source,
        'ts': timestamp.toIso8601String(),
        if (tagContext != null) 'tag': tagContext,
      };

  factory SuggestedPackRecord.fromJson(Map<String, dynamic> j) =>
      SuggestedPackRecord(
        packId: j['id'] as String,
        source: j['source'] as String,
        timestamp: DateTime.parse(j['ts'] as String),
        tagContext: j['tag'] as String?,
      );
}

class SuggestedTrainingPacksHistoryService {
  static const _prefsKey = 'suggested_pack_history';

  static Future<List<SuggestedPackRecord>> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Legacy format: list of JSON strings.
    final legacy = prefs.getStringList(_prefsKey);
    if (legacy != null) {
      final migrated = <SuggestedPackRecord>[];
      for (final e in legacy) {
        try {
          final data = jsonDecode(e);
          if (data is Map<String, dynamic>) {
            migrated.add(SuggestedPackRecord.fromJson(data));
          }
        } catch (_) {}
      }
      await prefs.remove(_prefsKey);
      await prefs.setString(
        _prefsKey,
        jsonEncode([for (final e in migrated) e.toJson()]),
      );
      return migrated;
    }

    final raw = prefs.getString(_prefsKey);
    if (raw == null) return <SuggestedPackRecord>[];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return [
          for (final e in data.whereType<Map<String, dynamic>>())
            SuggestedPackRecord.fromJson(e),
        ];
      }
    } catch (_) {}
    return <SuggestedPackRecord>[];
  }

  static Future<void> _save(List<SuggestedPackRecord> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final e in list) e.toJson()]),
    );
  }

  static Future<void> logSuggestion({
    required String packId,
    required String source,
    String? tagContext,
  }) async {
    final list = await _load();
    list.insert(
      0,
      SuggestedPackRecord(
        packId: packId,
        source: source,
        timestamp: DateTime.now(),
        tagContext: tagContext,
      ),
    );
    if (list.length > 100) list.removeRange(100, list.length);
    await _save(list);
    await SuggestionCooldownManager.markSuggested(packId);
  }

  static Future<List<SuggestedPackRecord>> getRecentSuggestions({
    int limit = 10,
  }) async {
    final list = await _load();
    return list.take(limit).toList();
  }

  static Future<bool> wasRecentlySuggested(
    String packId, {
    Duration within = const Duration(days: 30),
  }) async {
    final list = await _load();
    final cutoff = DateTime.now().subtract(within);
    for (final e in list) {
      if (e.packId == packId && e.timestamp.isAfter(cutoff)) return true;
    }
    return false;
  }

  static Future<void> clearStaleEntries({
    Duration maxAge = const Duration(days: 60),
  }) async {
    final list = await _load();
    final cutoff = DateTime.now().subtract(maxAge);
    list.removeWhere((e) => e.timestamp.isBefore(cutoff));
    await _save(list);
  }
}
