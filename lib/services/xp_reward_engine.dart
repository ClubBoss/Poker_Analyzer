import 'package:shared_preferences/shared_preferences.dart';

class XPRewardEngine {
  XPRewardEngine._();
  static final XPRewardEngine instance = XPRewardEngine._();

  static const String _xpKey = 'xp_total';

  Future<void> addXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_xpKey) ?? 0;
    await prefs.setInt(_xpKey, current + amount);
  }

  Future<int> getTotalXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }
}
