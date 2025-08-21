import '../models/decay_tag_reinforcement_event.dart';
import 'decay_session_tag_impact_recorder.dart';
import 'mastery_persistence_service.dart';
import 'tag_mastery_adjustment_log_service.dart';

/// Adjusts persisted tag mastery based on recent reinforcement history.
class DecayRecallMasteryIntegrator {
  final Future<List<DecayTagReinforcementEvent>> Function(String tag)
  _historyLoader;
  final MasteryPersistenceService _persistence;
  final TagMasteryAdjustmentLogService? _logger;
  final Duration staleThreshold;
  final double negativeDelta;
  final double positiveDelta;
  final double maxDelta;

  DecayRecallMasteryIntegrator({
    Future<List<DecayTagReinforcementEvent>> Function(String tag)?
    historyLoader,
    MasteryPersistenceService? persistence,
    TagMasteryAdjustmentLogService? logger,
    this.staleThreshold = const Duration(days: 30),
    this.negativeDelta = -0.02,
    this.positiveDelta = 0.01,
    this.maxDelta = 0.05,
  }) : _historyLoader =
           historyLoader ??
           DecaySessionTagImpactRecorder.instance.getRecentReinforcements,
       _persistence = persistence ?? MasteryPersistenceService(),
       _logger = logger;

  /// Runs the integrator, adjusting stored mastery values.
  Future<void> integrate({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final map = await _persistence.load();
    if (map.isEmpty) return;
    final updated = Map<String, double>.from(map);
    for (final entry in map.entries) {
      final tag = entry.key;
      final events = await _historyLoader(tag);
      int recent = 0;
      for (final e in events) {
        if (current.difference(e.timestamp) <= staleThreshold) {
          recent++;
        } else {
          break;
        }
      }
      double delta;
      if (recent == 0) {
        delta = negativeDelta;
      } else {
        delta = (positiveDelta * recent).clamp(-maxDelta, maxDelta);
      }
      delta = delta.clamp(-maxDelta, maxDelta);
      if (delta.abs() > 1e-6) {
        final newVal = (entry.value + delta).clamp(0.0, 1.0);
        updated[tag] = newVal;
        if (_logger != null) {
          await _logger.add(
            TagMasteryAdjustmentEntry(
              tag: tag,
              delta: delta,
              timestamp: current,
            ),
          );
        }
      }
    }
    await _persistence.save(updated);
  }
}
