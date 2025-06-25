import 'training_pack.dart';

class TrainingPackStats {
  final TrainingPack pack;
  final int total;
  final int mistakes;
  final double accuracy;
  final double rating;
  final DateTime? lastSession;

  TrainingPackStats({
    required this.pack,
    required this.total,
    required this.mistakes,
    required this.accuracy,
    required this.rating,
    required this.lastSession,
  });

  factory TrainingPackStats.fromPack(TrainingPack p) {
    final total = p.history.fold<int>(0, (p0, r) => p0 + r.total);
    final correct = p.history.fold<int>(0, (p0, r) => p0 + r.correct);
    final ratingAvg = p.hands.isNotEmpty
        ? p.hands.map((h) => h.rating).reduce((a, b) => a + b) / p.hands.length
        : 0.0;
    return TrainingPackStats(
      pack: p,
      total: total,
      mistakes: total - correct,
      accuracy: total > 0 ? correct * 100 / total : 0.0,
      rating: ratingAvg,
      lastSession: p.history.isNotEmpty ? p.history.last.date : null,
    );
  }
}
