import '../models/training_attempt.dart';

class TrainingPackStat {
  final double accuracy;
  final double ev;
  final double icm;
  final int attempts;

  TrainingPackStat({
    required this.accuracy,
    required this.ev,
    required this.icm,
    required this.attempts,
  });
}

class PackCompletionStatsService {
  PackCompletionStatsService();

  Map<String, TrainingPackStat> computeStats(List<TrainingAttempt> attempts) {
    final Map<String, Map<String, TrainingAttempt>> latest = {};
    for (final a in attempts) {
      final pack = latest.putIfAbsent(a.packId, () => {});
      final prev = pack[a.spotId];
      if (prev == null || a.timestamp.isAfter(prev.timestamp)) {
        pack[a.spotId] = a;
      }
    }

    final Map<String, TrainingPackStat> result = {};
    for (final entry in latest.entries) {
      final values = entry.value.values.toList();
      if (values.isEmpty) continue;
      double acc = 0;
      double ev = 0;
      double icm = 0;
      for (final v in values) {
        acc += v.accuracy;
        ev += v.ev;
        icm += v.icm;
      }
      final count = values.length;
      result[entry.key] = TrainingPackStat(
        accuracy: acc / count,
        ev: ev / count,
        icm: icm / count,
        attempts: count,
      );
    }

    return result;
  }
}
