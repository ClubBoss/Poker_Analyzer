import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class XPTrackerService extends ChangeNotifier {
  static const _xpKey = 'xp_total';
  static const targetXp = 10;
  static const achievementXp = 50;

  int _xp = 0;

  int get xp => _xp;
  int get level => _xp ~/ 100 + 1;
  int get nextLevelXp => level * 100;
  double get progress => (_xp % 100) / 100;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt(_xpKey) ?? 0;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, _xp);
  }

  Future<void> addXp(int value) async {
    _xp += value;
    await _save();
    notifyListeners();
  }
}
