import 'package:flutter/material.dart';
import 'player_progress_service.dart';
import 'achievement_engine.dart';
import 'next_step_engine.dart';

class FeedbackData {
  final IconData icon;
  final String text;
  const FeedbackData({required this.icon, required this.text});
}

class FeedbackService extends ChangeNotifier {
  final AchievementEngine achievements;
  final PlayerProgressService progress;
  final NextStepEngine next;
  FeedbackData? _data;
  FeedbackData? get data => _data;

  FeedbackService(
      {required this.achievements,
      required this.progress,
      required this.next}) {
    achievements.addListener(_update);
    progress.addListener(_update);
    next.addListener(_update);
    _update();
  }

  Achievement? _closestAchievement() {
    Achievement? best;
    var remain = 1 << 30;
    for (final a in achievements.achievements) {
      final r = a.nextTarget - a.progress;
      if (r > 0 && r < remain) {
        remain = r;
        best = a;
      }
    }
    return best;
  }

  HeroPosition? _weakPosition() {
    HeroPosition? worst;
    var acc = 101.0;
    for (final e in progress.progress.entries) {
      final pct = e.value.accuracy * 100;
      if (e.value.hands >= 20 && pct < acc) {
        acc = pct;
        worst = e.key;
      }
    }
    return worst;
  }

  void _update() {
    final step = next.suggestion;
    if (step != null) {
      _set(FeedbackData(
          icon: step.icon, text: '${step.title}: ${step.message}'));
      return;
    }
    final pos = _weakPosition();
    if (pos != null) {
      final a = progress.progress[pos]!.accuracy * 100;
      _set(FeedbackData(
          icon: Icons.school,
          text: 'Низкая точность на ${pos.label} - ${a.toStringAsFixed(1)}%'));
      return;
    }
    final ach = _closestAchievement();
    if (ach != null) {
      final left = ach.nextTarget - ach.progress;
      _set(FeedbackData(icon: ach.icon, text: 'Еще $left до ${ach.title}'));
      return;
    }
    _set(null);
  }

  void _set(FeedbackData? data) {
    if (data == null && _data == null) return;
    if (data != null && _data != null && data.text == _data!.text) return;
    _data = data;
    notifyListeners();
  }

  @override
  void dispose() {
    achievements.removeListener(_update);
    progress.removeListener(_update);
    next.removeListener(_update);
    super.dispose();
  }
}
