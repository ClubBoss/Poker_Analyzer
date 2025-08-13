import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skill_boost_log_entry.dart';

class SkillBoostLogService extends ChangeNotifier {
  static const _key = 'skill_boost_logs';
  SkillBoostLogService._();
  static final instance = SkillBoostLogService._();

  final List<SkillBoostLogEntry> _logs = [];

  List<SkillBoostLogEntry> get logs => List.unmodifiable(_logs);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _logs
            ..clear()
            ..addAll(data.map((e) =>
                SkillBoostLogEntry.fromJson(Map<String, dynamic>.from(e))));
          _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode([for (final l in _logs) l.toJson()]));
  }

  Future<void> add(SkillBoostLogEntry entry) async {
    _logs.insert(0, entry);
    await _save();
    notifyListeners();
  }

  /// Returns cumulative improvement per tag.
  Map<String, double> improvementByTag() {
    final map = <String, double>{};
    for (final l in _logs) {
      final key = l.tag.toLowerCase();
      map.update(key, (v) => v + (l.accuracyAfter - l.accuracyBefore),
          ifAbsent: () => l.accuracyAfter - l.accuracyBefore);
    }
    return map;
  }
}
