import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/decay_tag_reinforcement_event.dart';

class DecaySessionTagImpactRecorder {
  DecaySessionTagImpactRecorder._();
  static final DecaySessionTagImpactRecorder instance =
      DecaySessionTagImpactRecorder._();

  static const _prefix = 'decay_tag_reinf_';

  Future<List<DecayTagReinforcementEvent>> _load(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${tag.toLowerCase()}';
    final raw = prefs.getString(key);
    if (raw == null) return <DecayTagReinforcementEvent>[];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return [
          for (final e in data.whereType<Map>())
            DecayTagReinforcementEvent.fromJson(
                Map<String, dynamic>.from(e as Map)),
        ];
      }
    } catch (_) {}
    return <DecayTagReinforcementEvent>[];
  }

  Future<void> _save(String tag, List<DecayTagReinforcementEvent> list) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${tag.toLowerCase()}';
    await prefs.setString(
        key, jsonEncode([for (final e in list) e.toJson()]));
  }

  Future<void> recordSession(
      Map<String, double> tagDeltas, DateTime timestamp) async {
    for (final entry in tagDeltas.entries) {
      final tag = entry.key.toLowerCase();
      if (tag.isEmpty) continue;
      final list = await _load(tag);
      list.insert(
          0,
          DecayTagReinforcementEvent(
            tag: tag,
            delta: entry.value,
            timestamp: timestamp,
          ));
      while (list.length > 100) {
        list.removeLast();
      }
      await _save(tag, list);
    }
  }

  Future<List<DecayTagReinforcementEvent>> getRecentReinforcements(String tag) {
    return _load(tag);
  }
}
