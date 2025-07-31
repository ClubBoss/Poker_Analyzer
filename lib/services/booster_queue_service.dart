import '../models/v2/training_spot_v2.dart';

/// Stores training spots scheduled as boosters.
class BoosterQueueService {
  BoosterQueueService._();
  static final BoosterQueueService instance = BoosterQueueService._();

  final List<TrainingSpotV2> _queue = [];

  /// Adds [spots] to the queue if not already present by id.
  Future<void> addSpots(List<TrainingSpotV2> spots) async {
    for (final s in spots) {
      if (_queue.every((e) => e.id != s.id)) {
        _queue.add(s);
      }
    }
  }

  /// Returns queued spots.
  List<TrainingSpotV2> getQueue() => List.unmodifiable(_queue);

  void clear() => _queue.clear();
}
