import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/v2/training_pack_template.dart';
import 'adaptive_training_service.dart';
import 'achievement_engine.dart';
import 'weak_spot_recommendation_service.dart';
import 'player_style_service.dart';

class RecommendationTask {
  final String title;
  final IconData icon;
  final int remaining;
  const RecommendationTask({required this.title, required this.icon, required this.remaining});
}

class PersonalRecommendationService extends ChangeNotifier {
  final AchievementEngine achievements;
  final AdaptiveTrainingService adaptive;
  final WeakSpotRecommendationService weak;
  final PlayerStyleService style;
  PersonalRecommendationService({
    required this.achievements,
    required this.adaptive,
    required this.weak,
    required this.style,
  }) {
    achievements.addListener(() => unawaited(_update()));
    adaptive.recommendedNotifier.addListener(() => unawaited(_update()));
    weak.addListener(() => unawaited(_update()));
    style.addListener(() => unawaited(_update()));
    unawaited(_update());
  }

  final List<RecommendationTask> _tasks = [];
  List<TrainingPackTemplate> _packs = [];

  List<RecommendationTask> get tasks => List.unmodifiable(_tasks);
  List<TrainingPackTemplate> get packs => List.unmodifiable(_packs);

  Future<void> _update() async {
    final list = adaptive.recommendedNotifier.value.toList();
    final weakPack = await weak.buildPack();
    if (weakPack != null) list.insert(0, weakPack);
    _packs = list;
    _tasks
      ..clear()
      ..addAll(achievements.achievements.map((a) {
        final remain = a.nextTarget - a.progress;
        return RecommendationTask(title: a.title, icon: a.icon, remaining: remain);
      }).where((t) => t.remaining > 0));
    switch (style.style) {
      case PlayerStyle.aggressive:
        _tasks.insert(
          0,
          const RecommendationTask(
              title: 'Сбавьте агрессию ранних улиц',
              icon: Icons.trending_down,
              remaining: 1),
        );
        break;
      case PlayerStyle.passive:
        _tasks.insert(
          0,
          const RecommendationTask(
              title: 'Проявите больше агрессии',
              icon: Icons.trending_up,
              remaining: 1),
        );
        break;
      case PlayerStyle.neutral:
        break;
    }
    notifyListeners();
  }
}
