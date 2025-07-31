import '../models/v2/training_spot_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores training spots scheduled as boosters.

class BoosterQueueService {
  BoosterQueueService._();
  static final BoosterQueueService instance = BoosterQueueService._();

  static const _lastKey = 'booster_queue_last_used';

  final List<TrainingSpotV2> _queue = [];
  DateTime? _lastUsedAt;

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

  Future<DateTime?> lastUsed() async {
    if (_lastUsedAt != null) return _lastUsedAt;
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastKey);
    _lastUsedAt = str != null ? DateTime.tryParse(str) : null;
    return _lastUsedAt;
  }

  Future<void> markUsed({DateTime? time}) async {
    _lastUsedAt = time ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, _lastUsedAt!.toIso8601String());
  }
}
