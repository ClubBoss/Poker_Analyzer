import 'training_session_fingerprint_logger_service.dart';

class TrainingTimelineDaySummary {
  final DateTime date;
  final int sessionCount;
  final double avgAccuracy;
  final Set<String> tags;
  final int handCount;

  TrainingTimelineDaySummary({
    required this.date,
    required this.sessionCount,
    required this.avgAccuracy,
    required this.tags,
    required this.handCount,
  });
}

class TrainingSessionFingerprintTimelineService {
  final TrainingSessionFingerprintLoggerService logger;

  TrainingSessionFingerprintTimelineService({
    TrainingSessionFingerprintLoggerService? logger,
  }) : logger = logger ?? TrainingSessionFingerprintLoggerService();

  Future<List<TrainingTimelineDaySummary>> generateTimeline() async {
    final sessions = await logger.getAll();
    final map = <DateTime, List<TrainingSessionFingerprint>>{};
    for (final s in sessions) {
      final day = DateTime(
        s.completedAt.year,
        s.completedAt.month,
        s.completedAt.day,
      );
      map.putIfAbsent(day, () => []).add(s);
    }
    final days = map.keys.toList()..sort();
    final summaries = <TrainingTimelineDaySummary>[];
    for (final day in days) {
      final daySessions = map[day]!;
      final tags = <String>{};
      var totalCorrect = 0;
      var totalSpots = 0;
      for (final s in daySessions) {
        tags.addAll(s.tags);
        totalCorrect += s.correct;
        totalSpots += s.totalSpots;
      }
      final avgAccuracy = totalSpots > 0 ? totalCorrect / totalSpots : 0.0;
      summaries.add(
        TrainingTimelineDaySummary(
          date: day,
          sessionCount: daySessions.length,
          avgAccuracy: avgAccuracy,
          tags: tags,
          handCount: totalSpots,
        ),
      );
    }
    return summaries;
  }
}
