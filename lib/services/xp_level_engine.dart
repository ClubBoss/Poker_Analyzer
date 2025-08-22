import 'dart:math';

/// Information about the current XP level state.
class XPLevelInfo {
  final int level;
  final int currentXP;
  final int xpToNext;

  XPLevelInfo({
    required this.level,
    required this.currentXP,
    required this.xpToNext,
  });
}

class XPLevelEngine {
  XPLevelEngine._();

  static final XPLevelEngine instance = XPLevelEngine._();

  static const double _exponent = 1.5;
  static const int _base = 100;

  /// Returns the XP required to reach the start of [level].
  int xpForLevel(int level) {
    if (level <= 1) return 0;
    return (_base * pow(level - 1, _exponent)).round();
  }

  /// Returns the current level for the given total XP.
  int getLevel(int totalXp) {
    var level = 1;
    while (xpForLevel(level + 1) <= totalXp) {
      level += 1;
    }
    return level;
  }

  /// Returns progress to the next level as a value between 0 and 1.
  double getProgressToNextLevel(int totalXp) {
    final level = getLevel(totalXp);
    final prevLevelXp = xpForLevel(level);
    final nextLevelXp = xpForLevel(level + 1);
    if (nextLevelXp == prevLevelXp) return 0;
    return (totalXp - prevLevelXp) / (nextLevelXp - prevLevelXp);
  }

  /// Computes level info from [totalXp].
  static XPLevelInfo computeFromTotalXP(int totalXp) {
    final engine = XPLevelEngine.instance;
    final level = engine.getLevel(totalXp);
    final current = totalXp - engine.xpForLevel(level);
    final xpToNext = engine.xpForLevel(level + 1) - totalXp;
    return XPLevelInfo(level: level, currentXP: current, xpToNext: xpToNext);
  }
}
