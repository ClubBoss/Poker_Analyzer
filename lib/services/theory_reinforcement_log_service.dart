import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reinforcement_log.dart';

class TheoryReinforcementLogService {
  TheoryReinforcementLogService._();
  static final instance = TheoryReinforcementLogService._();

  static const _prefsKey = 'theory_reinforcement_logs';

  Future<List<ReinforcementLog>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return <ReinforcementLog>[];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return [
          for (final e in data.whereType<Map>())
            ReinforcementLog.fromJson(Map<String, dynamic>.from(e as Map)),
        ];
      }
    } catch (_) {}
    return <ReinforcementLog>[];
  }

  Future<void> _save(List<ReinforcementLog> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final l in list) l.toJson()]),
    );
  }

  Future<void> logInjection(String id, String type, String source) async {
    final list = await _load();
    list.insert(
      0,
      ReinforcementLog(
        id: id,
        type: type,
        source: source,
        timestamp: DateTime.now(),
      ),
    );
    if (list.length > 500) list.removeRange(500, list.length);
    await _save(list);
  }

  Future<List<ReinforcementLog>> getRecent({Duration? within}) async {
    final list = await _load();
    if (within == null) return list;
    final cutoff = DateTime.now().subtract(within);
    return [
      for (final l in list)
        if (l.timestamp != null && l.timestamp!.isAfter(cutoff)) l,
    ];
  }
}
