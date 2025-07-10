import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/v2/training_pack_template.dart';
import 'adaptive_training_service.dart';
import 'achievement_engine.dart';

class RecommendationTask {
  final String title;
  final IconData icon;
  final int remaining;
  const RecommendationTask({required this.title, required this.icon, required this.remaining});
}

class PersonalRecommendationService extends ChangeNotifier {
  final AchievementEngine achievements;
  final AdaptiveTrainingService adaptive;
  PersonalRecommendationService({required this.achievements, required this.adaptive}) {
    achievements.addListener(_update);
    adaptive.recommendedNotifier.addListener(_update);
    _update();
  }

  final List<RecommendationTask> _tasks = [];
  List<TrainingPackTemplate> _packs = [];

  List<RecommendationTask> get tasks => List.unmodifiable(_tasks);
  List<TrainingPackTemplate> get packs => List.unmodifiable(_packs);

  void _update() {
    _packs = adaptive.recommendedNotifier.value.toList();
    _tasks
      ..clear()
      ..addAll(achievements.achievements.map((a) {
        final remain = a.nextTarget - a.progress;
        return RecommendationTask(title: a.title, icon: a.icon, remaining: remain);
      }).where((t) => t.remaining > 0));
    notifyListeners();
  }
}
