import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mistake_tag.dart';

class MistakeTagHistoryService extends ChangeNotifier {
  static const _key = 'mistake_tag_counts';

  final Map<MistakeTag, int> _counts = {};
  Map<MistakeTag, int> get counts => Map.unmodifiable(_counts);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          for (final entry in data.entries) {
            for (final t in MistakeTag.values) {
              if (t.name == entry.key) {
                _counts[t] = (entry.value as num).toInt();
                break;
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final e in _counts.entries) e.key.name: e.value};
    await prefs.setString(_key, jsonEncode(map));
  }

  Future<void> addTags(List<MistakeTag> tags) async {
    if (tags.isEmpty) return;
    for (final t in tags) {
      _counts[t] = (_counts[t] ?? 0) + 1;
    }
    await _save();
    notifyListeners();
  }
}
