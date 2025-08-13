import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v2/training_pack_template.dart';
import 'adaptive_training_service.dart';
import 'achievement_engine.dart';
import 'weak_spot_recommendation_service.dart';
import 'player_style_service.dart';
import 'player_style_forecast_service.dart';
import 'progress_forecast_service.dart';
import 'training_pack_stats_service.dart';

class RecommendationTask {
  final String title;
  final IconData icon;
  final int remaining;
  const RecommendationTask(
      {required this.title, required this.icon, required this.remaining});
}

class PersonalRecommendationService extends ChangeNotifier {
  final AchievementEngine achievements;
  final AdaptiveTrainingService adaptive;
  final WeakSpotRecommendationService weak;
  final PlayerStyleService style;
  final PlayerStyleForecastService forecast;
  final ProgressForecastService progress;
  Timer? _debounce;
  PersonalRecommendationService({
    required this.achievements,
    required this.adaptive,
    required this.weak,
    required this.style,
    required this.forecast,
    required this.progress,
  }) {
    achievements.addListener(() => unawaited(_update()));
    adaptive.recommendedNotifier.addListener(() => unawaited(_update()));
    weak.addListener(() => unawaited(_update()));
    style.addListener(() => unawaited(_update()));
    forecast.addListener(() => unawaited(_update()));
    progress.addListener(() => unawaited(_update()));
    unawaited(_update());
  }

  final List<RecommendationTask> _tasks = [];
  List<TrainingPackTemplate> _packs = [];

  List<RecommendationTask> get tasks => List.unmodifiable(_tasks);
  List<TrainingPackTemplate> get packs => List.unmodifiable(_packs);

  Future<void> _performUpdate() async {
    final list = adaptive.recommendedNotifier.value.toList();
    final weakPack = await weak.buildPack();
    if (weakPack != null) list.insert(0, weakPack);
    _packs = list;
    _tasks
      ..clear()
      ..addAll(achievements.achievements.map((a) {
        final remain = a.nextTarget - a.progress;
        return RecommendationTask(
            title: a.title, icon: a.icon, remaining: remain);
      }).where((t) => t.remaining > 0));
    switch (forecast.forecast) {
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
    final prog = progress.forecast;
    if (prog.accuracy < 0.7) {
      _tasks.insert(
        0,
        const RecommendationTask(
            title: 'Работайте над точностью',
            icon: Icons.bar_chart,
            remaining: 1),
      );
    }
    if (prog.ev < 0) {
      _tasks.insert(
        0,
        const RecommendationTask(
            title: 'Улучшите EV', icon: Icons.show_chart, remaining: 1),
      );
    }
    if (prog.icm < 0) {
      _tasks.insert(
        0,
        const RecommendationTask(
            title: 'Улучшите ICM', icon: Icons.pie_chart, remaining: 1),
      );
    }
    notifyListeners();
  }

  Future<void> _update() async {
    _debounce?.cancel();
    final completer = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 100), () async {
      _debounce = null;
      await _performUpdate();
      completer.complete();
    });
    return completer.future;
  }

  Future<TrainingPackTemplate?> getTopRecommended() async {
    final prefs = await SharedPreferences.getInstance();
    for (final t in _packs) {
      final completed = prefs.getBool('completed_tpl_${t.id}') ?? false;
      final stat = await TrainingPackStatsService.getStats(t.id);
      final idx = stat?.lastIndex ?? 0;
      if (!completed || idx < t.spots.length) return t;
    }
    return null;
  }
}
