import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/achievement_service.dart';
import 'learning_path_progress_service.dart';
import 'learning_path_completion_service.dart';
import 'training_stats_service.dart';

/// Engine that unlocks achievements based on learning path progress.
class AchievementTriggerEngine {
  AchievementTriggerEngine._();
  static final instance = AchievementTriggerEngine._();

  /// When true, preferences are not touched and state is kept in memory.
  bool mock = false;
  final Set<String> _mockUnlocked = {};

  static String _key(String id) => 'ach_trigger_$id';

  Future<bool> _isUnlocked(String id) async {
    if (mock) return _mockUnlocked.contains(id);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(id)) ?? false;
  }

  Future<void> _markUnlocked(String id) async {
    if (mock) {
      _mockUnlocked.add(id);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(id), true);
    }
    if (!AchievementService.instance.isUnlocked(id)) {
      await AchievementService.instance.unlock(id);
    }
  }

  /// Checks all triggers and unlocks achievements if conditions met.
  Future<void> checkAndTriggerAchievements() async {
    await _checkFirstTraining();
    await _checkBeginnerStage();
    await _checkThreeStages();
    await _checkPathCompleted();
  }

  Future<void> _checkFirstTraining() async {
    if (await _isUnlocked('first_training_done')) return;
    final stats = TrainingStatsService.instance;
    if (stats != null && stats.sessionsCompleted > 0) {
      await _markUnlocked('first_training_done');
    }
  }

  Future<void> _checkThreeStages() async {
    if (await _isUnlocked('learning_path_3')) return;
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    final completedCount = stages
        .where(
          (s) => LearningPathProgressService.instance.isStageCompleted(s.items),
        )
        .length;
    if (completedCount >= 3) {
      await _markUnlocked('learning_path_3');
    }
  }

  Future<void> _checkBeginnerStage() async {
    if (await _isUnlocked('beginner_master')) return;
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    final stage = stages.firstWhereOrNull(
      (s) => s.title.toLowerCase() == 'beginner',
    );
    if (stage != null &&
        LearningPathProgressService.instance.isStageCompleted(stage.items)) {
      await _markUnlocked('beginner_master');
    }
  }

  Future<void> _checkPathCompleted() async {
    if (await _isUnlocked('path_completed')) return;
    final done =
        await LearningPathProgressService.instance.isAllStagesCompleted();
    if (done) {
      await LearningPathCompletionService.instance.markPathCompleted();
      await _markUnlocked('path_completed');
    }
  }
}
