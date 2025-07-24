import 'dart:math';

class XPLevelEngine {
  XPLevelEngine._();

  static final XPLevelEngine instance = XPLevelEngine._();

  /// Returns the current level for the given total XP.
  int getLevel(int totalXp) {
    return sqrt(totalXp / 100).floor() + 1;
  }

  /// Returns progress to the next level as a value between 0 and 1.
  double getProgressToNextLevel(int totalXp) {
    final level = getLevel(totalXp);
    final prevLevelXp = xpForLevel(level);
    final nextLevelXp = xpForLevel(level + 1);
    if (nextLevelXp == prevLevelXp) return 0;
    return (totalXp - prevLevelXp) / (nextLevelXp - prevLevelXp);
  }

  /// Returns the XP required to reach the start of [level].
  int xpForLevel(int level) {
    if (level <= 1) return 0;
    return 100 * pow(level - 1, 2).toInt();
  }
}
