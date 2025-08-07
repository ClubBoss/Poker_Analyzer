import '../models/session_log.dart';
import '../repositories/training_session_log_repository.dart';

class ABComparisonResult {
  final double accuracyA;
  final double accuracyB;
  final double timeA;
  final double timeB;
  final double retentionA;
  final double retentionB;
  final int sampleSizeA;
  final int sampleSizeB;
  final int earlyDropA;
  final int earlyDropB;

  const ABComparisonResult({
    required this.accuracyA,
    required this.accuracyB,
    required this.timeA,
    required this.timeB,
    required this.retentionA,
    required this.retentionB,
    required this.sampleSizeA,
    required this.sampleSizeB,
    required this.earlyDropA,
    required this.earlyDropB,
  });
}

/// Compares metrics between two training run variants.
class TrainingRunABComparatorService {
  final TrainingSessionLogRepository repository;
  TrainingRunABComparatorService({required this.repository});

  /// Compares metrics for [packIdA]/[variantA] vs [packIdB]/[variantB].
  ABComparisonResult compare({
    required String packIdA,
    required String packIdB,
    String? variantA,
    String? variantB,
  }) {
    final listA =
        repository.getLogs(packId: packIdA, variant: variantA);
    final listB =
        repository.getLogs(packId: packIdB, variant: variantB);
    return compareLogs(listA, listB);
  }

  /// Compares two lists of logs and computes aggregate metrics.
  ABComparisonResult compareLogs(
      List<SessionLog> listA, List<SessionLog> listB) {
    final maxSpots = _maxSpots([...listA, ...listB]);
    return ABComparisonResult(
      accuracyA: _averageAccuracy(listA),
      accuracyB: _averageAccuracy(listB),
      timeA: _averageTime(listA),
      timeB: _averageTime(listB),
      retentionA: _retention(listA),
      retentionB: _retention(listB),
      sampleSizeA: listA.length,
      sampleSizeB: listB.length,
      earlyDropA: _earlyDrops(listA, maxSpots),
      earlyDropB: _earlyDrops(listB, maxSpots),
    );
  }

  double _averageAccuracy(List<SessionLog> logs) {
    var correct = 0;
    var total = 0;
    for (final l in logs) {
      correct += l.correctCount;
      total += l.correctCount + l.mistakeCount;
    }
    return total == 0 ? 0.0 : correct / total;
  }

  double _averageTime(List<SessionLog> logs) {
    if (logs.isEmpty) return 0.0;
    final sum = logs
        .map((l) => l.completedAt.difference(l.startedAt).inSeconds)
        .fold<int>(0, (a, b) => a + b);
    return sum / logs.length;
  }

  double _retention(List<SessionLog> logs) {
    if (logs.length <= 1) return 0.0;
    return (logs.length - 1) / logs.length;
  }

  int _earlyDrops(List<SessionLog> logs, int maxSpots) {
    if (maxSpots == 0) return 0;
    final threshold = maxSpots / 2;
    return logs
        .where((l) => l.correctCount + l.mistakeCount < threshold)
        .length;
  }

  int _maxSpots(List<SessionLog> logs) {
    var max = 0;
    for (final l in logs) {
      final played = l.correctCount + l.mistakeCount;
      if (played > max) max = played;
    }
    return max;
  }
}
