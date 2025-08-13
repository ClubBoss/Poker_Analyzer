import 'dart:async';
import 'package:flutter/foundation.dart';

import 'mixed_drill_history_service.dart';
import '../models/mixed_drill_stat.dart';

class WeeklyDrillStats {
  final double accuracy;
  final int total;
  final int streak;
  final double improvementPct;
  const WeeklyDrillStats({
    required this.accuracy,
    required this.total,
    required this.streak,
    required this.improvementPct,
  });
}

class WeeklyDrillStatsService extends ChangeNotifier {
  final MixedDrillHistoryService history;
  WeeklyDrillStats? _stats;
  Timer? _timer;

  WeeklyDrillStatsService({required this.history});

  WeeklyDrillStats? get stats => _stats;

  void load() {
    _compute();
    history.addListener(_compute);
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _compute());
  }

  void _compute() {
    final list = history.stats;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final prevStart = start.subtract(const Duration(days: 7));
    final lastWeek = <MixedDrillStat>[
      for (final s in list)
        if (!s.date.isBefore(start)) s
    ];
    final prevWeek = <MixedDrillStat>[
      for (final s in list)
        if (!s.date.isBefore(prevStart) && s.date.isBefore(start)) s
    ];
    if (lastWeek.isEmpty || prevWeek.isEmpty) {
      _stats = null;
      notifyListeners();
      return;
    }
    int total = 0, correct = 0;
    for (final s in lastWeek) {
      total += s.total;
      correct += s.correct;
    }
    final acc = total > 0 ? correct * 100 / total : 0.0;
    int pTotal = 0, pCorrect = 0;
    for (final s in prevWeek) {
      pTotal += s.total;
      pCorrect += s.correct;
    }
    final pAcc = pTotal > 0 ? pCorrect * 100 / pTotal : 0.0;
    int streak = 0;
    for (int i = 0;; i++) {
      final d =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final any = list.any((s) =>
          s.date.year == d.year &&
          s.date.month == d.month &&
          s.date.day == d.day);
      if (any) {
        streak += 1;
      } else {
        break;
      }
    }
    _stats = WeeklyDrillStats(
      accuracy: acc,
      total: total,
      streak: streak,
      improvementPct: acc - pAcc,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    history.removeListener(_compute);
    _timer?.cancel();
    super.dispose();
  }
}
