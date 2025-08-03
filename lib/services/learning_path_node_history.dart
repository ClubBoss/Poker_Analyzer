import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import '../models/node_visit.dart';

class LearningPathNodeHistory {
  LearningPathNodeHistory._();

  static final instance = LearningPathNodeHistory._();

  static const _prefsKey = 'learning_path_node_history';

  final Map<String, NodeVisit> _visits = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          for (final entry in data.entries) {
            final m = entry.value;
            if (m is Map) {
              _visits[entry.key.toString()] =
                  NodeVisit.fromJson(Map<String, dynamic>.from(m));
            }
          }
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    final map = {for (final e in _visits.entries) e.key: e.value.toJson()};
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> markVisited(String nodeId) async {
    await load();
    _visits.putIfAbsent(
      nodeId,
      () => NodeVisit(nodeId: nodeId, firstSeen: DateTime.now()),
    );
    await _save();
  }

  Future<void> markCompleted(String nodeId) async {
    await load();
    final now = DateTime.now();
    final visit = _visits[nodeId];
    if (visit == null) {
      _visits[nodeId] =
          NodeVisit(nodeId: nodeId, firstSeen: now, completedAt: now);
    } else if (visit.completedAt == null) {
      _visits[nodeId] = visit.copyWith(completedAt: now);
    }
    await _save();
  }

  bool isCompleted(String nodeId) {
    return _visits[nodeId]?.completedAt != null;
  }

  DateTime? lastVisit(String nodeId) {
    final v = _visits[nodeId];
    return v == null ? null : v.completedAt ?? v.firstSeen;
  }

  Future<void> clear() async {
    _visits.clear();
    final prefs = await PreferencesService.getInstance();
    await prefs.remove(_prefsKey);
  }
}
