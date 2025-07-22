import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mistake_tag.dart';
import '../models/training_spot_attempt.dart';

class MistakeTagHistoryService {
  static const _prefsKey = 'mistake_tag_history';

  final Map<String, _TagRecord> _history = {};

  Map<String, _TagRecord> get history =>
      {for (final e in _history.entries) e.key: e.value.copy()};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        _history.clear();
        data.forEach((key, value) {
          if (value is Map) {
            _history[key.toString()] =
                _TagRecord.fromJson(Map<String, dynamic>.from(value));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey,
        jsonEncode(
            {for (final e in _history.entries) e.key: e.value.toJson()}));
  }

  Future<void> record(
      List<MistakeTag> tags, TrainingSpotAttempt attempt) async {
    for (final t in tags) {
      final key = t.name;
      final rec = _history.putIfAbsent(key, () => _TagRecord());
      rec.count += 1;
      if (rec.examples.length < 5) {
        rec.examples.add(attempt);
      }
    }
    await _save();
  }

  Future<void> clear() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

class _TagRecord {
  int count;
  final List<TrainingSpotAttempt> examples;
  _TagRecord({this.count = 0, List<TrainingSpotAttempt>? examples})
      : examples = examples ?? [];

  Map<String, dynamic> toJson() => {
        'count': count,
        if (examples.isNotEmpty)
          'examples': [for (final e in examples) e.toJson()],
      };

  _TagRecord copy() => _TagRecord(
      count: count, examples: List<TrainingSpotAttempt>.from(examples));

  factory _TagRecord.fromJson(Map<String, dynamic> json) => _TagRecord(
        count: (json['count'] as num?)?.toInt() ?? 0,
        examples: [
          for (final e in (json['examples'] as List? ?? []))
            TrainingSpotAttempt.fromJson(Map<String, dynamic>.from(e as Map))
        ],
      );
}
