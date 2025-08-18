import 'dart:async';
import 'package:collection/collection.dart';

import '../models/user_goal.dart';
import 'pack_library_loader_service.dart';
import 'session_log_service.dart';
import 'tag_mastery_service.dart';
import 'goal_analytics_service.dart';

class GoalSuggestionEngine {
  final TagMasteryService mastery;
  final SessionLogService logs;

  GoalSuggestionEngine({required this.mastery, required this.logs});

  List<UserGoal>? _cache;
  DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<List<UserGoal>> suggestGoals({bool force = false}) async {
    if (!force &&
        _cache != null &&
        DateTime.now().difference(_cacheTime) < const Duration(hours: 12)) {
      return _cache!;
    }

    final goals = <UserGoal>[];
    final masteryMap = await mastery.computeMastery();
    final weakEntries = masteryMap.entries.where((e) => e.value < 0.8).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final used = <String>{};
    final now = DateTime.now();

    for (final e in weakEntries.take(3)) {
      final tag = e.key;
      if (!used.add('tag:$tag')) continue;
      goals.add(
        UserGoal(
          id: 'tag_${tag}_${now.millisecondsSinceEpoch}',
          title: 'Тег $tag: цель 80%',
          type: 'tag',
          target: 80,
          base: (e.value * 100).round(),
          createdAt: now,
          tag: tag,
          targetAccuracy: 80.0,
        ),
      );
    }

    await logs.load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;

    for (final log in logs.logs) {
      if (goals.length >= 5) break;
      final total = log.correctCount + log.mistakeCount;
      if (total == 0) continue;
      final acc = log.correctCount / total;
      if (acc >= 0.8) continue;
      final tpl = library.firstWhereOrNull((t) => t.id == log.templateId);
      if (tpl == null) continue;
      final key = 'pack:${tpl.id}';
      if (!used.add(key)) continue;
      goals.add(
        UserGoal(
          id: 'pack_${tpl.id}_${now.millisecondsSinceEpoch}',
          title: 'Повтори ${tpl.name}',
          type: 'pack',
          target: 80,
          base: (acc * 100).round(),
          createdAt: now,
          tag: tpl.id,
          targetAccuracy: 80.0,
        ),
      );
    }

    _cache = goals.take(5).toList();
    _cacheTime = DateTime.now();
    for (final g in _cache!) {
      unawaited(GoalAnalyticsService.instance.logGoalCreated(g));
    }
    return _cache!;
  }
}
