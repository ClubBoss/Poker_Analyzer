import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/foundation.dart';
import 'pack_library_service.dart';
import 'review_path_recommender.dart';
import 'skill_loss_detector.dart';

/// Persists a queue of training pack IDs scheduled for automatic launch.
class ScheduledTrainingQueueService extends ChangeNotifier {
  ScheduledTrainingQueueService._();
  static final ScheduledTrainingQueueService instance =
      ScheduledTrainingQueueService._();
  factory ScheduledTrainingQueueService() => instance;

  static const _prefsKey = 'scheduled_training_queue';

  final List<String> _queue = [];

  List<String> get queue => List.unmodifiable(_queue);

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _queue
            ..clear()
            ..addAll(data.whereType<String>());
        }
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_queue));
  }

  /// Adds [packId] to the queue if not already present.
  Future<void> add(String packId) async {
    if (_queue.contains(packId)) return;
    _queue.add(packId);
    await _save();
    notifyListeners();
  }

  /// Returns and removes the next scheduled pack ID, or `null` if none.
  Future<String?> pop() async {
    if (_queue.isEmpty) return null;
    final id = _queue.removeAt(0);
    await _save();
    notifyListeners();
    return id;
  }

  bool get hasItems => _queue.isNotEmpty;

  /// Automatically schedules recovery packs for the most urgent tags.
  Future<void> autoSchedule({
    required List<SkillLoss> losses,
    required List<MistakeCluster> mistakeClusters,
    required Map<String, double> goalMissRatesByTag,
    PackLibraryService? library,
    int maxCount = 3,
  }) async {
    const recommender = ReviewPathRecommender();
    final recs = recommender.suggestRecoveryPath(
      losses: losses,
      mistakeClusters: mistakeClusters,
      goalMissRatesByTag: goalMissRatesByTag,
    );

    final lib = library ?? PackLibraryService.instance;
    for (final r in recs.take(maxCount)) {
      final pack = await lib.findByTag(r.tag);
      if (pack != null) {
        await add(pack.id);
      }
    }
  }
}
