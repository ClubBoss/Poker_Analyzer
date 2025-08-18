import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/drill_result.dart';

class DrillHistoryService extends ChangeNotifier {
  static const _key = 'drill_history';
  final List<DrillResult> _results = [];

  List<DrillResult> get results => List.unmodifiable(_results);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          _results
            ..clear()
            ..addAll(
              list.map(
                (e) =>
                    DrillResult.fromJson(Map<String, dynamic>.from(e as Map)),
              ),
            );
          _results.sort((a, b) => b.date.compareTo(a.date));
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final r in _results) r.toJson()]),
    );
  }

  Future<void> add(DrillResult r) async {
    _results.insert(0, r);
    await _save();
    notifyListeners();
  }
}
