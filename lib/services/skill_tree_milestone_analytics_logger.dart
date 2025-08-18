import 'analytics_service.dart';

/// Logs key milestones in the skill tree such as node completions,
/// stage unlocks, stage completions and full track completions.
class SkillTreeMilestoneAnalyticsLogger {
  SkillTreeMilestoneAnalyticsLogger._();
  static final instance = SkillTreeMilestoneAnalyticsLogger._();

  final AnalyticsService _analytics = AnalyticsService.instance;

  Future<void> logNodeCompleted({
    required String trackId,
    required int stage,
    required String nodeId,
  }) async {
    await _log(
      'node_completed',
      trackId: trackId,
      stage: stage,
      nodeId: nodeId,
    );
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

  Future<void> logStageCompleted({
    required String trackId,
    required int stageIndex,
    required int totalStages,
  }) async {
    await _analytics.logEvent('skill_tree_stage_completed', {
      'trackId': trackId,
      'stageIndex': stageIndex,
      'totalStages': totalStages,
    });
  }

  Future<void> _log(
    String event, {
    required String trackId,
    int? stage,
    String? nodeId,
  }) async {
    await _analytics.logEvent(event, {
      'trackId': trackId,
      if (stage != null) 'stage': stage,
      if (nodeId != null) 'nodeId': nodeId,
    });
  }
}
