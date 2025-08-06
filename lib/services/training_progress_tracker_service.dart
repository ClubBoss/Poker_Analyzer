import 'dart:async';
import 'training_pack_stats_service.dart';
import 'training_pack_progress_service.dart';
import 'training_progress_notifier.dart';
import 'training_progress_storage_service.dart';

class TrainingProgressTrackerService {
  TrainingProgressTrackerService._({
    TrainingProgressStorageService? storage,
    TrainingProgressNotifier? notifier,
  })  : _storage = storage ?? const TrainingProgressStorageService(),
        notifier = notifier ?? TrainingProgressNotifier();

  static final instance = TrainingProgressTrackerService._();

  final TrainingProgressStorageService _storage;
  final TrainingProgressNotifier notifier;

  Future<Set<String>> getCompletedSpotIds(String packId) =>
      _storage.loadCompletedSpotIds(packId);

  Future<void> recordSpotCompleted(String packId, String spotId) async {
    final ids = await _storage.loadCompletedSpotIds(packId);
    if (ids.add(spotId)) {
      await _storage.saveCompletedSpotIds(packId, ids);
      notifier.notifyProgressChanged();
      TrainingPackProgressService.instance.invalidate(packId);
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

