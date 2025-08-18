import 'training_pack_template_service.dart';
import 'training_progress_tracker_service.dart';

class TrainingPackProgressStats {
  final int completedCount;
  final int totalCount;
  const TrainingPackProgressStats({
    required this.completedCount,
    required this.totalCount,
  });
}

/// Provides per-pack completion stats.
class TrainingPackProgressService {
  TrainingPackProgressService._();
  static final instance = TrainingPackProgressService._();

  final Map<String, TrainingPackProgressStats?> _cache = {};

  Future<TrainingPackProgressStats?> getStatsForPack(String packId) async {
    if (_cache.containsKey(packId)) return _cache[packId];
    final template = TrainingPackTemplateService.getById(packId);
    if (template == null) {
      _cache[packId] = null;
      return null;
    }
    final total = template.spots.isNotEmpty
        ? template.spots.length
        : template.spotCount;
    if (total <= 0) {
      _cache[packId] = null;
      return null;
    }
    final completed =
        (await TrainingProgressTrackerService.instance.getCompletedSpotIds(
          packId,
        )).length;
    final stats = TrainingPackProgressStats(
      completedCount: completed,
      totalCount: total,
    );
    _cache[packId] = stats;
    return stats;
  }

  void invalidate(String packId) => _cache.remove(packId);
}
