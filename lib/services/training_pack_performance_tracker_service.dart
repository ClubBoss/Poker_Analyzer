import 'package:flutter/foundation.dart';
import 'training_pack_stats_service.dart';

class TrainingPackPerformanceTrackerService extends ChangeNotifier {
  TrainingPackPerformanceTrackerService._();
  static final instance = TrainingPackPerformanceTrackerService._();

  Future<double?> recentAccuracy(String packId) async {
    final stat = await TrainingPackStatsService.getStats(packId);
    return stat?.accuracy;
  }

  Future<bool> meetsRequirements(
    String packId, {
    double? requiredAccuracy,
    int? minHands,
  }) async {
    if (requiredAccuracy != null) {
      final acc = await recentAccuracy(packId) ?? 0;
      if (acc < requiredAccuracy) return false;
    }
    if (minHands != null) {
      final hands = await TrainingPackStatsService.getHandsCompleted(packId);
      if (hands < minHands) return false;
    }
    return true;
  }
}
