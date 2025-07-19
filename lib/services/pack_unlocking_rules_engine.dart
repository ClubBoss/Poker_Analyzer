import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/unlock_rules.dart';
import 'learning_path_progress_service.dart';
import 'learning_path_service.dart';
import 'training_pack_stats_service.dart';

class UnlockCheckResult {
  final bool unlocked;
  final String? reason;
  const UnlockCheckResult(this.unlocked, [this.reason]);
}

class PackUnlockingRulesEngine {
  PackUnlockingRulesEngine._();
  static final instance = PackUnlockingRulesEngine._();

  bool mock = false;
  final Set<String> _mockCompleted = {};
  double _mockAverageEV = 0;
  bool _mockStarterCompleted = false;

  set mockAverageEV(double v) => _mockAverageEV = v;
  set mockStarterPathCompleted(bool v) => _mockStarterCompleted = v;

  Future<UnlockCheckResult> check(TrainingPackTemplateV2 pack) async {
    final rules = pack.unlockRules;
    if (rules == null) return const UnlockCheckResult(true);

    if (rules.requiredPacks.isNotEmpty) {
      for (final id in rules.requiredPacks) {
        final done = mock
            ? _mockCompleted.contains(id)
            : await LearningPathProgressService.instance.isCompleted(id);
        if (!done) return UnlockCheckResult(false, 'Завершите пак $id');
      }
    }

    if (rules.requiresStarterPathCompleted == true) {
      final completed = mock
          ? _mockStarterCompleted
          : await _isStarterPathCompleted();
      if (!completed) {
        return const UnlockCheckResult(false, 'Завершите starter path');
      }
    }

    if (rules.minEV != null) {
      final ev = mock
          ? _mockAverageEV
          : (await TrainingPackStatsService.getGlobalStats()).averageEV;
      if (ev < rules.minEV!) {
        return UnlockCheckResult(
            false, 'Средний EV < ${rules.minEV!.toStringAsFixed(2)}');
      }
    }

    return const UnlockCheckResult(true);
  }

  Future<bool> isUnlocked(TrainingPackTemplateV2 pack) async {
    final res = await check(pack);
    return res.unlocked;
  }

  Future<bool> _isStarterPathCompleted() async {
    final progress = await LearningPathService.instance.getStarterPathProgress();
    final total = LearningPathService.instance.buildStarterPath().length;
    return progress >= total;
  }

  void markMockCompleted(String id) => _mockCompleted.add(id);
  void resetMock() {
    _mockCompleted.clear();
    _mockAverageEV = 0;
    _mockStarterCompleted = false;
  }
}
