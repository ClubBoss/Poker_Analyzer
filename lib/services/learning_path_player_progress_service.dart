import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_path_player_progress.dart';

/// Persists [LearningPathProgress] for composed learning paths.
class LearningPathProgressService {
  LearningPathProgressService._();
  static final instance = LearningPathProgressService._();

  static const _prefsPrefix = 'learning.path.progress.';

  Future<LearningPathProgress> load(String pathId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsPrefix$pathId';
    final raw = prefs.getString(key);
    if (raw == null) return LearningPathProgress();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LearningPathProgress.fromJson(map);
    } catch (_) {
      await prefs.setString('${key}.bak', raw);
      await prefs.remove(key);
      return LearningPathProgress();
    }
  }

  Future<void> save(String pathId, LearningPathProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsPrefix$pathId';
    final raw = jsonEncode(progress.toJson());
    await prefs.setString(key, raw);
  }

  Future<void> reset(String pathId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsPrefix$pathId');
  }
}
