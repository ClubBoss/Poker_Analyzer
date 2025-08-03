import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/training_result.dart';

class TrainingHistoryController {
  TrainingHistoryController._();
  static final instance = TrainingHistoryController._();

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

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('training_history');
  }
}

