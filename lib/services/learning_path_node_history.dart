import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/node_visit.dart';

class LearningPathNodeHistory {
  LearningPathNodeHistory._();

  static final instance = LearningPathNodeHistory._();

  static const _prefsKey = 'learning_path_node_history';
  static const _autoKey = 'learning_path_auto_injected';

  final Map<String, NodeVisit> _visits = {};
  final Set<String> _autoInjected = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
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
    final rawAuto = prefs.getString(_autoKey);
    if (rawAuto != null && rawAuto.isNotEmpty) {
      _autoInjected.addAll(
        rawAuto.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }
    _loaded = true;
  }

  Future<void> _saveVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final e in _visits.entries) e.key: e.value.toJson()};
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> _saveAutoInjected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autoKey, _autoInjected.join(','));
  }

  Future<void> markVisited(String nodeId) async {
    await load();
    _visits.putIfAbsent(
      nodeId,
      () => NodeVisit(nodeId: nodeId, firstSeen: DateTime.now()),
    );
    await _saveVisits();
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
    await _saveVisits();
  }

  bool isCompleted(String nodeId) {
    return _visits[nodeId]?.completedAt != null;
  }

  DateTime? lastVisit(String nodeId) {
    final v = _visits[nodeId];
    return v == null ? null : v.completedAt ?? v.firstSeen;
  }

  Future<void> markAutoInjected(String nodeId) async {
    await load();
    if (_autoInjected.add(nodeId)) {
      await _saveAutoInjected();
    }
  }

  List<String> getAutoInjectedIds() => List<String>.from(_autoInjected);

  Future<void> clear() async {
    _visits.clear();
    _autoInjected.clear();
    _loaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_autoKey);
  }
}
