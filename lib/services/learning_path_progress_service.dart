import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

import 'training_progress_service.dart';
import 'pack_dependency_map.dart';
import 'smart_stage_unlock_engine.dart';

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
  final String? goalHint;
  final String? tip;
  final List<LearningStageItem> items;
  final bool isLocked;

  const LearningStageState({
    required this.title,
    required this.levelIndex,
    required this.goal,
    this.goalHint,
    this.tip,
    required this.items,
    this.isLocked = false,
  });
}

class LearningPathProgressService {
  LearningPathProgressService._();
  static final instance = LearningPathProgressService._();

  static const _introKey = 'learning_intro_seen';
  static const _customPathKey = 'custom_path_started';
  static const _customPathCompletedKey = 'custom_path_completed';
  static const _streakKey = 'daily_learning_goal_streak';
  static const _lastCompletedKey = 'daily_learning_goal_completed_at';
  static const _unlockedKey = 'unlocked_pack_ids';

  bool mock = false;
  final Map<String, bool> _mockCompleted = {};
  bool _mockIntroSeen = false;
  bool _mockCustomPathStarted = false;
  bool _mockCustomPathCompleted = false;
  bool unlockAllStages = false;
  final Map<String, bool> _mockTheoryViewed = {};

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
  static String _theoryKey(String id) => 'learning_theory_viewed_$id';

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

  Future<void> markCustomPathStarted() async {
    if (mock) {
      _mockCustomPathStarted = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customPathKey, true);
  }

  Future<void> markTheoryViewed(String stageId) async {
    if (mock) {
      _mockTheoryViewed[stageId] = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_theoryKey(stageId), true);
  }

  Future<bool> isTheoryViewed(String stageId) async {
    if (mock) return _mockTheoryViewed[stageId] == true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_theoryKey(stageId)) ?? false;
  }

  Future<bool> isCustomPathStarted() async {
    if (mock) return _mockCustomPathStarted;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_customPathKey) ?? false;
  }

  Future<void> markCustomPathCompleted() async {
    if (mock) {
      _mockCustomPathCompleted = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customPathCompletedKey, true);
  }

  Future<bool> isCustomPathCompleted() async {
    if (mock) return _mockCustomPathCompleted;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_customPathCompletedKey) ?? false;
  }

  Future<void> resetCustomPath() async {
    if (mock) {
      _mockCustomPathStarted = false;
      _mockCustomPathCompleted = false;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customPathKey);
    await prefs.remove(_customPathCompletedKey);
  }

  /// Resets both intro flag and stage progress.
  Future<void> resetAll() async {
    await resetProgress();
    await resetIntroSeen();
    await resetCustomPath();
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

  Future<void> resetStage(String stageId) async {
    final stages = await getCurrentStageState();
    final stage = stages.firstWhereOrNull(
        (s) => s.title.toLowerCase() == stageId.toLowerCase());
    if (stage == null) return;
    if (mock) {
      for (final item in stage.items) {
        if (item.templateId != null) {
          _mockCompleted.remove(item.templateId);
        }
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    for (final item in stage.items) {
      final id = item.templateId;
      if (id == null) continue;
      await prefs.remove(_key(id));
      await prefs.remove('progress_tpl_$id');
      await prefs.remove('completed_tpl_$id');
      await prefs.remove('completed_at_tpl_$id');
      await prefs.remove('last_accuracy_tpl_$id');
      await prefs.remove('last_accuracy_tpl_${id}_0');
      await prefs.remove('last_accuracy_tpl_${id}_1');
      await prefs.remove('last_accuracy_tpl_${id}_2');
    }
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
      const LearningStageState(
          levelIndex: 1,
          title: 'Beginner',
          goal: 'Освой базовый пуш-фолд',
          goalHint: 'Заверши все паки на 100%',
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
      const LearningStageState(
          levelIndex: 2,
          title: 'Intermediate',
          goal: 'Изучи ICM и диапазоны 20bb',
          goalHint: 'Пройди этап без ошибок',
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
      const LearningStageState(
          levelIndex: 3,
          title: 'Advanced',
          goal: 'Углуби стратегию и эксплойт',
          goalHint: 'Отточить эксплойтные решения',
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
      final stageUnlocked = unlockAllStages ||
          prevCompleted ||
          await SmartStageUnlockEngine.instance.isStageUnlocked(stage.title);
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
          goalHint: stage.goalHint,
          tip: stage.tip,
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

  Future<Map<String, dynamic>> exportProgress() async {
    if (mock) {
      final completed = [
        for (final e in _mockCompleted.entries)
          if (e.value) e.key
      ];
      final unlockedStages =
          await SmartStageUnlockEngine.instance.getUnlockedStages();
      return {
        'completedPackIds': completed,
        'introSeen': _mockIntroSeen,
        'customPathStarted': _mockCustomPathStarted,
        'customPathCompleted': _mockCustomPathCompleted,
        if (unlockedStages.isNotEmpty) 'unlockedStages': unlockedStages,
      };
    }
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs
        .getKeys()
        .where((k) => k.startsWith('learning_completed_') &&
            (prefs.getBool(k) ?? false))
        .map((k) => k.substring('learning_completed_'.length))
        .toList();
    final stages = await getCurrentStageState();
    final current = stages.firstWhereOrNull(
        (s) => !isStageCompleted(s.items));
    final data = <String, dynamic>{
      'completedPackIds': completed,
      'introSeen': prefs.getBool(_introKey) ?? false,
      'customPathStarted': prefs.getBool(_customPathKey) ?? false,
      'customPathCompleted': prefs.getBool(_customPathCompletedKey) ?? false,
    };
    final streak = prefs.getInt(_streakKey);
    if (streak != null) data['streakCount'] = streak;
    final last = prefs.getString(_lastCompletedKey);
    if (last != null) data['lastCompletedAt'] = last;
    final unlocked = prefs.getStringList(_unlockedKey);
    if (unlocked != null) data['unlockedPackIds'] = unlocked;
    final unlockedStages = await SmartStageUnlockEngine.instance.getUnlockedStages();
    if (unlockedStages.isNotEmpty) data['unlockedStages'] = unlockedStages;
    if (current != null) data['currentStageId'] = current.title;
    return data;
  }

  Future<void> importProgress(Map<String, dynamic> data) async {
    if (mock) {
      _mockCompleted
        ..clear()
        ..addEntries([
          for (final id in (data['completedPackIds'] as List? ?? const []))
            MapEntry(id as String, true)
        ]);
      _mockIntroSeen = data['introSeen'] == true;
      _mockCustomPathStarted = data['customPathStarted'] == true;
      _mockCustomPathCompleted = data['customPathCompleted'] == true;
      final stages = (data['unlockedStages'] as List?)?.whereType<String>().toList() ?? const [];
      await SmartStageUnlockEngine.instance.setUnlockedStages(stages);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('learning_completed_'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    final completed = data['completedPackIds'] as List? ?? const [];
    for (final id in completed) {
      if (id is String) {
        await prefs.setBool(_key(id), true);
      }
    }
    if (data.containsKey('introSeen')) {
      await prefs.setBool(_introKey, data['introSeen'] == true);
    }
    if (data.containsKey('customPathStarted')) {
      if (data['customPathStarted'] == true) {
        await prefs.setBool(_customPathKey, true);
      } else {
        await prefs.remove(_customPathKey);
      }
    }
    if (data.containsKey('customPathCompleted')) {
      if (data['customPathCompleted'] == true) {
        await prefs.setBool(_customPathCompletedKey, true);
      } else {
        await prefs.remove(_customPathCompletedKey);
      }
    }
    if (data.containsKey('streakCount')) {
      final val = data['streakCount'];
      if (val is num) {
        await prefs.setInt(_streakKey, val.toInt());
      }
    }
    if (data.containsKey('lastCompletedAt')) {
      final str = data['lastCompletedAt'];
      if (str is String) {
        await prefs.setString(_lastCompletedKey, str);
      }
    }
    if (data.containsKey('unlockedPackIds')) {
      final list = (data['unlockedPackIds'] as List?)
          ?.whereType<String>()
          .toList();
      if (list != null) {
        await prefs.setStringList(_unlockedKey, list);
      }
    }
    if (data.containsKey('unlockedStages')) {
      final stages = (data['unlockedStages'] as List?)?.whereType<String>().toList();
      if (stages != null) {
        await SmartStageUnlockEngine.instance.setUnlockedStages(stages);
      }
    }
    await PackDependencyMap.instance.recalc();
  }
}
