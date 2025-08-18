import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_path_stage_model.dart';

class TrainingPathStorageService {
  static const _key = 'training_paths_v2';

  const TrainingPathStorageService();

  Future<Map<String, List<LearningPathStageModel>>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) {
        final list = (v as List?) ?? [];
        return MapEntry(k, [
          for (final e in list)
            LearningPathStageModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ]);
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> save(String pathId, List<LearningPathStageModel> stages) async {
    final all = await _loadAll();
    all[pathId] = stages;
    final prefs = await SharedPreferences.getInstance();
    final map = all.map((k, v) => MapEntry(k, [for (final s in v) s.toJson()]));
    await prefs.setString(_key, jsonEncode(map));
  }
}
