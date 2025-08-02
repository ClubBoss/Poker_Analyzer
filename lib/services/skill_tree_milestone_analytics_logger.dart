import 'user_action_logger.dart';

/// Logs key milestones in the skill tree such as node completions,
/// stage unlocks and full track completions.
class SkillTreeMilestoneAnalyticsLogger {
  SkillTreeMilestoneAnalyticsLogger._();
  static final instance = SkillTreeMilestoneAnalyticsLogger._();

  Future<void> logNodeCompleted({
    required String trackId,
    required int stage,
    required String nodeId,
  }) async {
    await _log('node_completed',
        trackId: trackId, stage: stage, nodeId: nodeId);
  }

  Future<void> logStageUnlocked({
    required String trackId,
    required int stage,
  }) async {
    await _log('stage_unlocked', trackId: trackId, stage: stage);
  }

  Future<void> logTrackCompleted({required String trackId}) async {
    await _log('track_completed', trackId: trackId);
  }

  Future<void> _log(
    String event, {
    required String trackId,
    int? stage,
    String? nodeId,
  }) async {
    final data = <String, dynamic>{
      'event': event,
      'trackId': trackId,
      if (stage != null) 'stage': stage,
      if (nodeId != null) 'nodeId': nodeId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await UserActionLogger.instance.logEvent(data);
  }
}
