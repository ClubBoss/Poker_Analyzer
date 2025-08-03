import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_result.dart';

class TrainingHistoryService {
  TrainingHistoryService._();
  static final instance = TrainingHistoryService._();

  Future<List<TrainingResult>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('training_history') ?? [];
    final results = <TrainingResult>[];
    for (final item in stored) {
      try {
        final data = jsonDecode(item);
        if (data is Map<String, dynamic>) {
          results.add(
            TrainingResult.fromJson(Map<String, dynamic>.from(data)),
          );
        }
      } catch (_) {}
    }
    return results;
  }

  Future<void> saveHistory(List<TrainingResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    final list = [for (final r in history) jsonEncode(r.toJson())];
    await prefs.setStringList('training_history', list);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('training_history');
  }
}
