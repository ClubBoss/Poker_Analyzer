import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SuggestedPackLog {
  final String id;
  final String source;
  final DateTime timestamp;

  SuggestedPackLog({
    required this.id,
    required this.source,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'ts': timestamp.toIso8601String(),
      };

  factory SuggestedPackLog.fromJson(Map<String, dynamic> j) => SuggestedPackLog(
        id: j['id'] as String,
        source: j['source'] as String,
        timestamp: DateTime.parse(j['ts'] as String),
      );
}

class SuggestedTrainingPacksHistoryService {
  static const _prefsKey = 'suggested_pack_history';

  static Future<List<SuggestedPackLog>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    final list = <SuggestedPackLog>[];
    for (final e in raw) {
      try {
        final data = jsonDecode(e);
        if (data is Map<String, dynamic>) {
          list.add(SuggestedPackLog.fromJson(data));
        }
      } catch (_) {}
    }
    return list;
  }

  static Future<void> _save(List<SuggestedPackLog> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      [for (final e in list) jsonEncode(e.toJson())],
    );
  }

  static Future<void> logSuggestion({
    required String packId,
    required String source,
  }) async {
    final list = await _load();
    list.insert(
      0,
      SuggestedPackLog(
        id: packId,
        source: source,
        timestamp: DateTime.now(),
      ),
    );
    if (list.length > 100) list.removeRange(100, list.length);
    await _save(list);
  }

  static Future<List<SuggestedPackLog>> getRecentSuggestions({
    Duration since = const Duration(days: 30),
  }) async {
    final list = await _load();
    final cutoff = DateTime.now().subtract(since);
    return [for (final e in list) if (e.timestamp.isAfter(cutoff)) e];
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
