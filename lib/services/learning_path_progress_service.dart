import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'training_progress_service.dart';

enum LearningItemStatus { locked, available, inProgress, completed }

class LearningStageItem {
  final String title;
  final IconData icon;
  final double progress;
  final LearningItemStatus status;
  final String? templateId;

  const LearningStageItem({
    required this.title,
    required this.icon,
    required this.progress,
    required this.status,
    this.templateId,
  });
}

class LearningStageState {
  final String title;
  final int levelIndex;
  final String goal;
  final String? tip;
  final List<LearningStageItem> items;
  final bool isLocked;

  const LearningStageState({
    required this.title,
    required this.levelIndex,
    required this.goal,
    this.tip,
    required this.items,
    this.isLocked = false,
  });
}

class LearningPathProgressService {
  LearningPathProgressService._();
  static final instance = LearningPathProgressService._();

  static const _introKey = 'learning_intro_seen';

  bool mock = false;
  final Map<String, bool> _mockCompleted = {};
  bool _mockIntroSeen = false;
  bool unlockAllStages = false;

  /// Clears all learning path progress. Used for development/testing only.
  Future<void> resetProgress() async {
    if (mock) {
      _mockCompleted.clear();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith('learning_completed_'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  static String _key(String id) => 'learning_completed_$id';

  Future<bool> hasSeenIntro() async {
    if (mock) return _mockIntroSeen;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introKey) ?? false;
  }

  Future<void> markIntroSeen() async {
    if (mock) {
      _mockIntroSeen = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introKey, true);
  }

  Future<void> resetIntroSeen() async {
    if (mock) {
      _mockIntroSeen = false;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_introKey);
  }

  /// Resets both intro flag and stage progress.
  Future<void> resetAll() async {
    await resetProgress();
    await resetIntroSeen();
  }

  Future<void> markCompleted(String templateId) async {
    if (mock) {
      _mockCompleted[templateId] = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(templateId), true);
  }

  Future<bool> isCompleted(String templateId) async {
    if (mock) return _mockCompleted[templateId] == true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(templateId)) ?? false;
  }

  bool isStageCompleted(List<LearningStageItem> items) {
    return items.every((e) => e.status == LearningItemStatus.completed);
  }

  Future<List<LearningStageState>> getCurrentStageState() async {
    final prefs = mock ? null : await SharedPreferences.getInstance();

    bool completed(String id) {
      if (mock) return _mockCompleted[id] == true;
      return prefs?.getBool(_key(id)) ?? false;
    }

    final stages = [
      LearningStageState(
          levelIndex: 1,
          title: 'Beginner',
          goal: 'Освой базовый пуш-фолд',
          tip:
              "Попробуй сначала сыграть пак 'Push/Fold Basics', чтобы освоиться с концепцией",
          items: [
        LearningStageItem(
          title: 'Push/Fold Basics',
          icon: Icons.play_circle_fill,
          progress: 0.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_10bb',
        ),
        LearningStageItem(
          title: '10bb Ranges',
          icon: Icons.school,
          progress: 0.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_10bb',
        ),
        LearningStageItem(
          title: '15bb Ranges',
          icon: Icons.school,
          progress: 0.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_15bb',
        ),
      ]),
      LearningStageState(
          levelIndex: 2,
          title: 'Intermediate',
          goal: 'Изучи ICM и диапазоны 20bb',
          tip: 'Закрепи навыки прошлого уровня и изучи влияние ICM.',
          items: [
        LearningStageItem(
          title: 'ICM Concepts',
          icon: Icons.insights,
          progress: 0.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_12bb',
        ),
        LearningStageItem(
          title: 'Shoving Charts 20bb',
          icon: Icons.table_chart,
          progress: 0.0,
          status: LearningItemStatus.locked,
          templateId: 'starter_pushfold_20bb',
        ),
      ]),
      LearningStageState(
          levelIndex: 3,
          title: 'Advanced',
          goal: 'Углуби стратегию и эксплойт',
          tip: 'Ищи возможности для эксплойта соперников.',
          items: [
        LearningStageItem(
          title: 'Exploit Spots',
          icon: Icons.lightbulb_outline,
          progress: 0.0,
          status: LearningItemStatus.locked,
        ),
      ]),
    ];

    final result = <LearningStageState>[];
    var prevCompleted = true;
    for (final stage in stages) {
      final items = <LearningStageItem>[];
      var stageUnlocked = unlockAllStages || prevCompleted;
      var itemUnlock = stageUnlocked;
      for (final item in stage.items) {
        final tplId = item.templateId;
        final done = tplId != null && completed(tplId);
        double prog = item.progress;
        if (tplId != null) {
          prog = await TrainingProgressService.instance.getProgress(tplId);
        }
        LearningItemStatus status;
        if (!stageUnlocked) {
          status = LearningItemStatus.locked;
          prog = 0.0;
        } else if (done) {
          status = LearningItemStatus.completed;
        } else if (prog > 0 && prog < 1 && tplId != null) {
          status = LearningItemStatus.inProgress;
        } else if (itemUnlock) {
          status = LearningItemStatus.available;
        } else {
          status = LearningItemStatus.locked;
        }
        items.add(LearningStageItem(
          title: item.title,
          icon: item.icon,
          progress: stageUnlocked ? prog : 0.0,
          status: status,
          templateId: item.templateId,
        ));
        itemUnlock = itemUnlock && done;
      }
      final completedStage = isStageCompleted(items);
      result.add(LearningStageState(
          title: stage.title,
          levelIndex: stage.levelIndex,
          goal: stage.goal,
          items: items,
          isLocked: !stageUnlocked));
      prevCompleted = unlockAllStages ? true : completedStage;
    }
    return result;
  }

  /// Returns true if every learning stage item has been completed.
  Future<bool> isAllStagesCompleted() async {
    final stages = await getCurrentStageState();
    for (final stage in stages) {
      for (final item in stage.items) {
        if (item.templateId != null &&
            item.status != LearningItemStatus.completed) {
          return false;
        }
      }
    }
    return true;
  }
}
