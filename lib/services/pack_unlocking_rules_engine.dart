import 'package:flutter/foundation.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/unlock_rule.dart';
import 'learning_path_progress_service.dart';
import 'learning_path_service.dart';
import 'training_pack_stats_service.dart';

class UnlockCheckResult {
  final bool unlocked;
  final String? reason;
  UnlockCheckResult(this.unlocked, [this.reason]);
}

class PackUnlockingRulesEngine {
  PackUnlockingRulesEngine._();
  static final instance = PackUnlockingRulesEngine._();

  bool mock = false;
  bool devOverride = false;
  final Set<String> _mockCompleted = {};
  double _mockAverageEV = 0;
  bool _mockStarterCompleted = false;
  bool _mockCustomPathCompleted = false;

  final Map<String, UnlockRule> _rules = {
    // Example rule for demonstration
    'advanced_pack': const UnlockRule(
      id: 'advanced_pack',
      unlockHint: 'Завершите пак 10BB Starter',
      requiresPackCompleted: 'starter_pushfold_10bb',
      requiresEV: 0.85,
      requiresGoal: 'completed_customPath',
    ),
  };

  set mockAverageEV(double v) => _mockAverageEV = v;
  set mockStarterPathCompleted(bool v) => _mockStarterCompleted = v;
  set mockCustomPathCompleted(bool v) => _mockCustomPathCompleted = v;

  UnlockRule? getUnlockRule(TrainingPackTemplateV2 pack) {
    return _rules[pack.id];
  }

  Future<UnlockCheckResult> check(TrainingPackTemplateV2 pack) async {
    if (kDebugMode && devOverride) return const UnlockCheckResult(true);
    final rules = getUnlockRule(pack) ?? pack.unlockRules == null
        ? null
        : UnlockRule(
            id: pack.id,
            unlockHint: pack.unlockRules!.unlockHint,
            requiresPackCompleted: pack.unlockRules!.requiredPacks.isNotEmpty
                ? pack.unlockRules!.requiredPacks.first
                : null,
            requiresEV: pack.unlockRules!.minEV,
            requiresStageCompleted:
                pack.unlockRules!.requiresStarterPathCompleted == true
                ? 'starter'
                : null,
          );
    if (rules == null) return const UnlockCheckResult(true);
    final String? hint = rules.unlockHint;

    if (rules.requiresPackCompleted != null) {
      final id = rules.requiresPackCompleted!;
      final done = mock
          ? _mockCompleted.contains(id)
          : await LearningPathProgressService.instance.isCompleted(id);
      if (!done) return UnlockCheckResult(false, hint ?? 'Завершите пак $id');
    }

    if (rules.requiresStageCompleted != null &&
        rules.requiresStageCompleted == 'starter') {
      final completed = mock
          ? _mockStarterCompleted
          : await _isStarterPathCompleted();
      if (!completed) {
        return UnlockCheckResult(false, hint ?? 'Завершите starter path');
      }
    }

    if (rules.requiresEV != null) {
      final ev = mock
          ? _mockAverageEV
          : (await TrainingPackStatsService.getGlobalStats()).averageEV;
      if (ev < rules.requiresEV!) {
        return UnlockCheckResult(
          false,
          hint ?? 'Средний EV < ${rules.requiresEV!.toStringAsFixed(2)}',
        );
      }
    }

    if (rules.requiresGoal != null) {
      bool achieved = false;
      if (rules.requiresGoal == 'completed_customPath') {
        achieved = mock
            ? _mockCustomPathCompleted
            : await LearningPathProgressService.instance
                  .isCustomPathCompleted();
      }
      if (!achieved) {
        return UnlockCheckResult(false, hint);
      }
    }

    return const UnlockCheckResult(true);
  }

  Future<bool> isUnlocked(TrainingPackTemplateV2 pack) async {
    final res = await check(pack);
    return res.unlocked;
  }

  Future<bool> _isStarterPathCompleted() async {
    final progress = await LearningPathService.instance
        .getStarterPathProgress();
    final total = LearningPathService.instance.buildStarterPath().length;
    return progress >= total;
  }

  void markMockCompleted(String id) => _mockCompleted.add(id);
  void resetMock() {
    _mockCompleted.clear();
    _mockAverageEV = 0;
    _mockStarterCompleted = false;
    _mockCustomPathCompleted = false;
    devOverride = false;
  }
}
