import '../models/pinned_learning_item.dart';
import 'pinned_interaction_logger_service.dart';

/// Detects whether a pinned item should be temporarily excluded from nudging
/// due to user fatigue.
class NudgeFatigueDetectorService {
  NudgeFatigueDetectorService({PinnedInteractionLoggerService? logger})
      : _logger = logger ?? PinnedInteractionLoggerService.instance;

  /// Singleton instance.
  static final NudgeFatigueDetectorService instance =
      NudgeFatigueDetectorService();

  final PinnedInteractionLoggerService _logger;

  /// Returns `true` if the user appears fatigued with the given [item].
  ///
  /// A user is considered fatigued when:
  /// * They have dismissed the nudge at least 3 times and never opened it.
  /// * OR the ratio of opens to dismissals is below 0.2 with more than
  ///   5 impressions.
  Future<bool> isFatigued(PinnedLearningItem item) async {
    final stats = await _logger.getStatsFor(item.id);
    final now = DateTime.now();
    final impressions = (stats['impressions'] as int?) ?? 0;
    final opens = (stats['opens'] as int?) ?? 0;
    final dismissals = (stats['dismissals'] as int?) ?? 0;
    final lastOpenedMillis = stats['lastOpened'] as int?;
    final lastDismissedMillis = stats['lastDismissed'] as int?;

    if (lastOpenedMillis != null) {
      final lastOpened = DateTime.fromMillisecondsSinceEpoch(lastOpenedMillis);
      if (now.difference(lastOpened) < const Duration(days: 7)) {
        return false;
      }
    }

    var fatigued = false;

    if (dismissals >= 3 && opens == 0) {
      fatigued = true;
    } else if (impressions > 5 && dismissals > 0) {
      final ratio = opens / dismissals;
      if (ratio < 0.2) fatigued = true;
    }

    if (!fatigued) return false;

    if (lastDismissedMillis == null) return false;
    final lastDismissed = DateTime.fromMillisecondsSinceEpoch(
      lastDismissedMillis,
    );
    final sinceDismiss = now.difference(lastDismissed);
    if (sinceDismiss < const Duration(days: 3)) return true;
    if (sinceDismiss >= const Duration(days: 7)) return false;

    return true;
  }

  /// Clears any recorded fatigue for the given [id].
  Future<void> clearFatigueFor(String id) async {
    await _logger.clearFatigueFor(id);
  }
}
