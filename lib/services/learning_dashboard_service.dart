import '../models/track_play_history.dart';
import 'mastery_forecast_engine.dart';

class LearningDashboardData {
  final int goalsCompleted;
  final double averageAccuracy;
  final double evGainEstimate;
  final int tagsImproved;
  final int? streakDays;

  const LearningDashboardData({
    required this.goalsCompleted,
    required this.averageAccuracy,
    required this.evGainEstimate,
    required this.tagsImproved,
    this.streakDays,
  });
}

class LearningDashboardService {
  final MasteryForecastEngine forecast;

  const LearningDashboardService({
    this.forecast = const MasteryForecastEngine(),
  });

  LearningDashboardData getDashboardData({
    required List<TrackPlayHistory> trackHistory,
    required Map<String, double> currentMastery,
    required Map<String, double> previousMastery,
  }) {
    final completed = trackHistory.where((h) => h.completedAt != null);
    final goalsCompleted = {for (final h in completed) h.goalId}.length;

    final accValues = [
      for (final h in completed)
        if (h.accuracy != null) h.accuracy!,
    ];
    final averageAccuracy = accValues.isEmpty
        ? 0.0
        : accValues.reduce((a, b) => a + b) / accValues.length;

    final dates = {
      for (final h in completed)
        DateTime(h.completedAt!.year, h.completedAt!.month, h.completedAt!.day),
    }.toList()
      ..sort();
    int streak = 0;
    if (dates.isNotEmpty) {
      final today = DateTime.now();
      for (int i = 0;; i++) {
        final day = DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: i));
        if (dates.contains(day)) {
          streak += 1;
        } else {
          break;
        }
      }
    }

    final Set<String> tags = {
      ...currentMastery.keys.map((e) => e.trim().toLowerCase()),
      ...previousMastery.keys.map((e) => e.trim().toLowerCase()),
    };
    int tagsImproved = 0;
    double evGain = 0.0;
    for (final tag in tags) {
      final prev = previousMastery[tag] ?? 0.0;
      final curr = currentMastery[tag] ?? 0.0;
      if (curr > prev) {
        tagsImproved += 1;
        final before = forecast.estimateEvGain(
          tag: tag,
          tagMastery: previousMastery,
        );
        final after = forecast.estimateEvGain(
          tag: tag,
          tagMastery: currentMastery,
        );
        evGain += before - after;
      }
    }

    return LearningDashboardData(
      goalsCompleted: goalsCompleted,
      averageAccuracy: averageAccuracy,
      evGainEstimate: evGain,
      tagsImproved: tagsImproved,
      streakDays: streak == 0 ? null : streak,
    );
  }
}
