import 'package:poker_analyzer/services/completed_training_pack_registry.dart';

/// Summary of a completed training session.
class CompletedSessionSummary {
  final String fingerprint;
  final String trainingType;
  final double? accuracy;
  final DateTime timestamp;
  final String yaml;

  const CompletedSessionSummary({
    required this.fingerprint,
    required this.trainingType,
    this.accuracy,
    required this.timestamp,
    required this.yaml,
  });
}

/// Loads and summarizes completed training sessions.
class CompletedSessionSummaryService {
  final CompletedTrainingPackRegistry registry;

  const CompletedSessionSummaryService({
    CompletedTrainingPackRegistry? registry,
  }) : registry = registry ?? CompletedTrainingPackRegistry();

  /// Returns summaries for all completed sessions sorted by most recent.
  Future<List<CompletedSessionSummary>> loadSummaries() async {
    final fingerprints = await registry.listCompletedFingerprints();
    final summaries = <CompletedSessionSummary>[];
    for (final fp in fingerprints) {
      final data = await registry.getCompletedPackData(fp);
      if (data == null) continue;
      final yaml = data['yaml'];
      final timestampStr = data['timestamp'];
      final type = data['type'];
      if (yaml is! String || timestampStr is! String || type is! String) {
        continue;
      }
      DateTime? ts;
      try {
        ts = DateTime.parse(timestampStr);
      } catch (_) {}
      if (ts == null) continue;
      double? accuracy;
      final acc = data['accuracy'];
      if (acc is num) accuracy = acc.toDouble();
      summaries.add(
        CompletedSessionSummary(
          fingerprint: fp,
          trainingType: type,
          accuracy: accuracy,
          timestamp: ts,
          yaml: yaml,
        ),
      );
    }
    summaries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return summaries;
  }
}
