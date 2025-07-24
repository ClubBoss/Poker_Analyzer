import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinsService extends ChangeNotifier {
  static CoinsService? _instance;
  static CoinsService get instance => _instance!;

  CoinsService() {
    _instance = this;
  }

  static const _key = 'user_coins';
  int _coins = 0;

  int get coins => _coins;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(_key) ?? 0;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _coins);
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    await _save();
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _coins -= amount;
    await _save();
    notifyListeners();
    return true;
  }
}
