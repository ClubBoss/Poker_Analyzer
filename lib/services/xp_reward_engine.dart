
class XPRewardEngine {
  XPRewardEngine._();
  static final XPRewardEngine instance = XPRewardEngine._();

  static const int levelStep = 500;

  static const String _xpKey = 'xp_total';

  Future<void> addXp(int amount) async {
    final prefs = await PreferencesService.getInstance();
    final current = prefs.getInt(_xpKey) ?? 0;
    await prefs.setInt(_xpKey, current + amount);
  }

  Future<int> getTotalXp() async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }
}

int getLevel(int totalXp) => (totalXp ~/ XPRewardEngine.levelStep) + 1;

int getXpForNextLevel(int currentXp) {
  final level = getLevel(currentXp);
  return level * XPRewardEngine.levelStep;
}
