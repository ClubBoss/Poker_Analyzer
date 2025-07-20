import 'learning_path_unlock_engine.dart';

/// Convenience service that delegates to [LearningPathUnlockEngine]
/// to fetch textual explanations for locked tracks.
class TrackUnlockReasonService {
  TrackUnlockReasonService._();
  static final instance = TrackUnlockReasonService._();

  Future<String?> getReason(String trackId) {
    return LearningPathUnlockEngine.instance.getUnlockReason(trackId);
  }
}
