import 'package:flutter/foundation.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

class RewardService extends ChangeNotifier {
  static const _balanceKey = 'reward_balance';
  int _balance = 0;
  int get balance => _balance;

  Future<void> load() async {
    final prefs = await PreferencesService.getInstance();
    _balance = prefs.getInt(_balanceKey) ?? 0;
  }

  Future<void> add(int value) async {
    _balance += value;
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt(_balanceKey, _balance);
    notifyListeners();
  }
}
