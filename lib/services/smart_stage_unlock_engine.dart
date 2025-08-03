
import 'learning_path_progress_service.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

class SmartStageUnlockEngine {
  SmartStageUnlockEngine._();
  static final instance = SmartStageUnlockEngine._();

  static const _prefsKey = 'smart_unlocked_stages';

  bool mock = false;
  final Set<String> _mockUnlocked = {};

  Future<List<String>> _loadUnlocked() async {
    if (mock) return _mockUnlocked.toList();
    final prefs = await PreferencesService.getInstance();
    return prefs.getStringList(_prefsKey) ?? <String>[];
  }

  Future<void> _saveUnlocked(List<String> stages) async {
    if (mock) {
      _mockUnlocked
        ..clear()
        ..addAll(stages);
      return;
    }
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_prefsKey, stages);
  }

  Future<void> setUnlockedStages(List<String> stages) async {
    await _saveUnlocked(List<String>.from(stages));
  }

  Future<bool> isStageUnlocked(String title) async {
    final list = await _loadUnlocked();
    return list.contains(title);
  }

  Future<List<String>> getUnlockedStages() async {
    return _loadUnlocked();
  }

  Future<void> checkAndUnlockNextStage({bool force = false}) async {
    final stages = await LearningPathProgressService.instance.getCurrentStageState();
    final unlocked = await _loadUnlocked();
    for (var i = 0; i < stages.length - 1; i++) {
      final stage = stages[i];
      final next = stages[i + 1];
      final done = LearningPathProgressService.instance.isStageCompleted(stage.items);
      if ((done || force) && !unlocked.contains(next.title)) {
        unlocked.add(next.title);
        await _saveUnlocked(unlocked);
        break;
      }
      if (!done && !force) break;
    }
  }

  Future<void> forceUnlockNextStage() async {
    await checkAndUnlockNextStage(force: true);
  }
}
