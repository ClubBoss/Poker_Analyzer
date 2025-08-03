import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'adaptive_learning_flow_engine.dart';
import 'learning_plan_cache_models.dart';

/// Persists the last generated [AdaptiveLearningPlan] to allow instant resume
/// after app restart.
class LearningPlanCache {
  static const _key = 'learning_plan_cache';

  const LearningPlanCache();

  /// Saves [plan] to local storage.
  Future<void> save(AdaptiveLearningPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final data = CachedLearningPlan.fromPlan(plan).toJson();
    await prefs.setString(_key, jsonEncode(data));
  }

  /// Loads cached plan if available. Returns `null` if the cache is missing
  /// or corrupted.
  Future<AdaptiveLearningPlan?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        return CachedLearningPlan.fromJson(
          Map<String, dynamic>.from(data),
        ).toPlan();
      }
    } catch (_) {}
    return null;
  }
}
