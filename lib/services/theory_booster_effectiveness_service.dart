import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/booster_effect_log.dart';

class TheoryBoosterEffectivenessService {
  TheoryBoosterEffectivenessService._();
  static final instance = TheoryBoosterEffectivenessService._();

  static const _prefsKey = 'booster_effectiveness_logs';

  Future<List<BoosterEffectLog>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return <BoosterEffectLog>[];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return [
          for (final e in data.whereType<Map>())
            BoosterEffectLog.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
    return <BoosterEffectLog>[];
  }

  Future<void> _save(List<BoosterEffectLog> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final l in list) l.toJson()]),
    );
  }

  Future<void> trackBoosterEffect(
    String id,
    String type,
    double deltaEV,
    int spotCount,
  ) async {
    final list = await _load();
    list.insert(
      0,
      BoosterEffectLog(
        id: id,
        type: type,
        deltaEV: double.parse(deltaEV.toStringAsFixed(4)),
        spotsTracked: spotCount,
        timestamp: DateTime.now(),
      ),
    );
    if (list.length > 500) list.removeRange(500, list.length);
    await _save(list);
  }

  Future<List<BoosterEffectLog>> getImpactStats(String id) async {
    final list = await _load();
    return [
      for (final l in list)
        if (l.id == id) l
    ];
  }
}
