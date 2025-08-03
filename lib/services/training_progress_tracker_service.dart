import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'training_pack_stats_service.dart';

class TrainingProgressTrackerService extends ChangeNotifier {
  TrainingProgressTrackerService._();
  static final instance = TrainingProgressTrackerService._();

  String _key(String packId) => 'pack_progress_$packId';

  Future<Set<String>> getCompletedSpotIds(String packId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key(packId));
    return list?.toSet() ?? {};
  }

  Future<void> recordSpotCompleted(String packId, String spotId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(packId);
    final ids = prefs.getStringList(key)?.toSet() ?? {};
    if (ids.add(spotId)) {
      await prefs.setStringList(key, ids.toList());
      notifyListeners();
    }
  }

  Future<bool> meetsPerformanceRequirements(
    String packId, {
    double? requiresAccuracy,
    int? requiresVolume,
  }) async {
    if (requiresAccuracy != null) {
      final stat = await TrainingPackStatsService.getStats(packId);
      final acc = (stat?.accuracy ?? 0) * 100;
      if (acc < requiresAccuracy) return false;
    }
    if (requiresVolume != null) {
      final completed = await TrainingPackStatsService.getHandsCompleted(packId);
      if (completed < requiresVolume) return false;
    }
    return true;
  }
}

