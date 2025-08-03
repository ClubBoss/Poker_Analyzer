import 'dart:math';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/foundation.dart';
import '../models/achievement_progress.dart';

class RewardSystemService extends ChangeNotifier {
  static RewardSystemService? _instance;
  static RewardSystemService get instance => _instance!;

  RewardSystemService() {
    _instance = this;
  }

  static const _xpKey = 'reward_total_xp';
  static const _levelKey = 'reward_level';

  int _totalXP = 0;
  int _currentLevel = 1;

  int get totalXP => _totalXP;
  int get currentLevel => _currentLevel;

  int get xpToNextLevel => _xpForLevel(_currentLevel);

  int get _cumulativeXpBeforeLevel {
    int sum = 0;
    for (int i = 1; i < _currentLevel; i++) {
      sum += _xpForLevel(i);
    }
    return sum;
  }

  int get xpProgress => _totalXP - _cumulativeXpBeforeLevel;

  double get progress => xpToNextLevel == 0 ? 0 : xpProgress / xpToNextLevel;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _totalXP = prefs.getInt(_xpKey) ?? 0;
    _currentLevel = prefs.getInt(_levelKey) ?? 1;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_xpKey, _totalXP);
    await prefs.setInt(_levelKey, _currentLevel);
  }

  int _xpForLevel(int level) {
    if (level <= 1) return 100;
    return 250 * pow(2, level - 2).toInt();
  }

  Future<void> applyAchievementReward(AchievementProgress progress) async {
    final int xpGained = progress.newLevel * 50;
    _totalXP += xpGained;
    while (_totalXP >= _cumulativeXpBeforeLevel + _xpForLevel(_currentLevel)) {
      _currentLevel += 1;
    }
    await _save();
    notifyListeners();
  }
}
