import 'package:shared_preferences/shared_preferences.dart';

class TheoryStageProgressTracker {
  TheoryStageProgressTracker._();
  static final TheoryStageProgressTracker instance =
      TheoryStageProgressTracker._();

  static const _completedPrefix = 'theory_stage_completed_';
  static const _masteryPrefix = 'theory_stage_mastery_';

  Future<bool> isCompleted(String stageId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_completedPrefix$stageId') ?? false;
  }

  Future<double> getMastery(String stageId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('$_masteryPrefix$stageId') ?? 0.0;
  }

  Future<void> markCompleted(String stageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_completedPrefix$stageId', true);
  }

  Future<void> updateMastery(String stageId, double score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_masteryPrefix$stageId', score.clamp(0.0, 1.0));
  }

  Future<Map<String, double>> getTheoryStageProgressList() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, double>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_masteryPrefix)) {
        final id = key.substring(_masteryPrefix.length);
        final val = prefs.getDouble(key);
        if (val != null) result[id] = val;
      }
    }
    return result;
  }
}
