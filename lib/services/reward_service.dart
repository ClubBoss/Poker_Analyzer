import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardService extends ChangeNotifier {
  static const _balanceKey = 'reward_balance';
  int _balance = 0;
  int get balance => _balance;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt(_balanceKey) ?? 0;
  }

  Future<void> add(int value) async {
    _balance += value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, _balance);
    notifyListeners();
  }
}
