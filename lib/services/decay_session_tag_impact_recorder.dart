import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/decay_tag_reinforcement_event.dart';

class DecaySessionTagImpactRecorder {
  DecaySessionTagImpactRecorder._();
  static final DecaySessionTagImpactRecorder instance =
      DecaySessionTagImpactRecorder._();

  static const _prefix = 'decay_tag_reinf_';
  static const _allKey = 'decay_tag_reinf_all';

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
            DecayTagReinforcementEvent.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
    return <DecayTagReinforcementEvent>[];
  }

  Future<void> _save(String tag, List<DecayTagReinforcementEvent> list) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${tag.toLowerCase()}';
    await prefs.setString(key, jsonEncode([for (final e in list) e.toJson()]));
  }

  Future<List<DecayTagReinforcementEvent>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_allKey);
    if (raw == null) return <DecayTagReinforcementEvent>[];
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return [
          for (final e in data.whereType<Map>())
            DecayTagReinforcementEvent.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
    return <DecayTagReinforcementEvent>[];
  }

  Future<void> _saveAll(List<DecayTagReinforcementEvent> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _allKey,
      jsonEncode([for (final e in list) e.toJson()]),
    );
  }

  Future<void> recordSession(
    Map<String, double> tagDeltas,
    DateTime timestamp,
  ) async {
    final all = await _loadAll();
    for (final entry in tagDeltas.entries) {
      final tag = entry.key.toLowerCase();
      if (tag.isEmpty) continue;
      final event = DecayTagReinforcementEvent(
        tag: tag,
        delta: entry.value,
        timestamp: timestamp,
      );
      final list = await _load(tag);
      list.insert(0, event);
      while (list.length > 100) {
        list.removeLast();
      }
      await _save(tag, list);
      all.insert(0, event);
    }
    await _saveAll(all);
  }

  Future<List<DecayTagReinforcementEvent>> getRecentReinforcements(String tag) {
    return _load(tag);
  }

  Future<List<DecayTagReinforcementEvent>> loadAllEvents() {
    return _loadAll();
  }

  Future<List<DecayTagReinforcementEvent>> loadByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await _loadAll();
    return [
      for (final e in all)
        if (!e.timestamp.isBefore(start) && !e.timestamp.isAfter(end)) e,
    ];
  }
}
