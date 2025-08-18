import 'dart:async';

import 'user_action_logger.dart';
import 'training_pack_stats_service.dart';

class _SessionSnapshot {
  final double accuracy;
  final int hands;
  const _SessionSnapshot({required this.accuracy, required this.hands});
}

class _SessionMeta {
  final double? evPercent;
  final double? accuracyBefore;
  final double? accuracyAfter;
  final int? handsBefore;
  final int? handsAfter;
  final bool? unlockGoalReached;
  const _SessionMeta({
    this.evPercent,
    this.accuracyBefore,
    this.accuracyAfter,
    this.handsBefore,
    this.handsAfter,
    this.unlockGoalReached,
  });
}

/// Logs training session start events.
class TrainingProgressLogger {
  TrainingProgressLogger._();

  static final _starts = <String, _SessionSnapshot>{};
  static final _meta = <String, _SessionMeta>{};

  /// Records the start of a training session for the given [packId].
  static Future<void> startSession(String packId) async {
    final stat = await TrainingPackStatsService.getStats(packId);
    final hands = await TrainingPackStatsService.getHandsCompleted(packId);
    _starts[packId] = _SessionSnapshot(
      accuracy: stat?.accuracy ?? 0,
      hands: hands,
    );
    unawaited(UserActionLogger.instance.log('training_session_start:$packId'));
  }

  static _SessionMeta? consumeMeta(String packId) => _meta.remove(packId);

  /// Records completion of a training session for the given [packId].
  static Future<void> finishSession(
    String packId,
    int hands, {
    double? evPercent,
    double? requiredAccuracy,
    int? minHands,
  }) async {
    final before = _starts.remove(packId);
    final statAfter = await TrainingPackStatsService.getStats(packId);
    final handsAfter = await TrainingPackStatsService.getHandsCompleted(packId);
    final accuracyAfter = statAfter?.accuracy ?? 0;
    final accuracyBefore = before?.accuracy;
    final handsBefore = before?.hands;

    bool? unlockGoalReached;
    if (requiredAccuracy != null || minHands != null) {
      unlockGoalReached =
          (requiredAccuracy == null ||
              accuracyAfter * 100 >= requiredAccuracy) &&
          (minHands == null || handsAfter >= minHands);
    }

    _meta[packId] = _SessionMeta(
      evPercent: evPercent,
      accuracyBefore: accuracyBefore != null ? accuracyBefore * 100 : null,
      accuracyAfter: accuracyAfter * 100,
      handsBefore: handsBefore,
      handsAfter: handsAfter,
      unlockGoalReached: unlockGoalReached,
    );

    unawaited(
      UserActionLogger.instance.logEvent({
        'event': 'training_session_complete',
        'id': packId,
        'hands': hands,
        if (evPercent != null) 'evPercent': evPercent,
        if (accuracyBefore != null) 'accuracyBefore': accuracyBefore * 100,
        'accuracyAfter': accuracyAfter * 100,
        if (handsBefore != null) 'handsBefore': handsBefore,
        'handsAfter': handsAfter,
        if (unlockGoalReached != null) 'unlockGoalReached': unlockGoalReached,
      }),
    );
  }

  /// Legacy wrapper.
  static Future<void> completeSession(String packId, int hands) async {
    await finishSession(packId, hands);
  }
}
