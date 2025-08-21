import 'learning_track_engine.dart';
import 'track_lock_evaluator.dart';

/// Provides textual explanations for why learning tracks are locked.
class TrackUnlockReasonService {
  final TrackLockEvaluator lockEvaluator;
  final LearningTrackEngine trackEngine;

  TrackUnlockReasonService({
    TrackLockEvaluator? lockEvaluator,
    LearningTrackEngine trackEngine = const LearningTrackEngine(),
  }) : lockEvaluator =
           lockEvaluator ??
           TrackLockEvaluator(
             prerequisites: const {
               'live_exploit': 'mtt_pro',
               'leak_fixer': 'live_exploit',
             },
           ),
       trackEngine = trackEngine;

  static final TrackUnlockReasonService instance = TrackUnlockReasonService();

  /// Returns `null` if [trackId] is unlocked, otherwise a message explaining
  /// which prerequisite track must be completed.
  Future<String?> getUnlockReason(String trackId) async {
    if (!await lockEvaluator.isLocked(trackId)) return null;
    final prereqId = lockEvaluator.prerequisites[trackId];
    if (prereqId == null) return null;
    final prereqTrack = trackEngine.getTrackById(prereqId);
    final prereqName = prereqTrack?.title ?? prereqId;
    return "Чтобы разблокировать этот трек, завершите трек '$prereqName'.";
  }
}
