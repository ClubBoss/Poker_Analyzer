import 'training_session_fingerprint_logger_service.dart';

/// Tracks how often skill tags appear across training sessions.
class SkillTagSessionCoverageTrackerService {
  final TrainingSessionFingerprintLoggerService logger;

  SkillTagSessionCoverageTrackerService({
    TrainingSessionFingerprintLoggerService? logger,
  }) : logger = logger ?? TrainingSessionFingerprintLoggerService();

  /// Computes how frequently each tag appears in [sessions].
  ///
  /// If [sessions] is omitted, all logged sessions will be used.
  Future<Map<String, int>> computeCoverage([
    List<TrainingSessionFingerprint>? sessions,
  ]) async {
    final list = sessions ?? await logger.getAll();
    final freq = <String, int>{};
    for (final s in list) {
      for (final tag in s.tags) {
        freq.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return freq;
  }

  /// Returns tags occurring less than [threshold] times.
  Future<List<String>> lowFrequencyTags(int threshold, [
    List<TrainingSessionFingerprint>? sessions,
  ]) async {
    final coverage = await computeCoverage(sessions);
    return [
      for (final entry in coverage.entries)
        if (entry.value < threshold) entry.key
    ];
  }
}
