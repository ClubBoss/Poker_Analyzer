import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardService extends ChangeNotifier {
  static const _rewardKey = 'weekly_reward_pending';
  String? _reward;

  String? get reward => _reward;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _reward = prefs.getString(_rewardKey);
  }

  Future<void> _save(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_rewardKey);
    } else {
      await prefs.setString(_rewardKey, value);
    }
  }

  Future<void> setReward(String value) async {
    _reward = value;
    await _save(value);
    notifyListeners();
  }

  Future<void> clear() async {
    _reward = null;
    await _save(null);
    notifyListeners();
  }

  String randomReward() {
    const rewards = [
      'XP Boost',
      'Training Pack',
      'Extra Mistake Slot',
      'Card Skin'
    ];
    return rewards[Random().nextInt(rewards.length)];
  }
}
