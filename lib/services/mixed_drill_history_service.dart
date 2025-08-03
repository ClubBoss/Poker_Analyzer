import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/foundation.dart';

import '../models/mixed_drill_stat.dart';

class MixedDrillHistoryService extends ChangeNotifier {
  static const _key = 'mixed_drill_history';
  final List<MixedDrillStat> _stats = [];

  List<MixedDrillStat> get stats => List.unmodifiable(_stats);

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          _stats
            ..clear()
            ..addAll(list.map((e) => MixedDrillStat.fromJson(Map<String, dynamic>.from(e as Map))));
          _stats.sort((a, b) => b.date.compareTo(a.date));
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_key, jsonEncode([for (final s in _stats) s.toJson()]));
  }

  Future<void> add(MixedDrillStat s) async {
    _stats.insert(0, s);
    if (_stats.length > 20) _stats.removeRange(20, _stats.length);
    await _save();
    notifyListeners();
  }
}
