import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'training_stats_service.dart';

class WeeklyChallenge {
  final String title;
  final String type;
  final int target;
  const WeeklyChallenge(this.title, this.type, this.target);
}

class WeeklyChallengeService extends ChangeNotifier {
  static const _indexKey = 'weekly_challenge_index';
  static const _startKey = 'weekly_challenge_start';
  static const _handsKey = 'weekly_challenge_base_hands';
  static const _mistakesKey = 'weekly_challenge_base_mistakes';

  final TrainingStatsService stats;
  WeeklyChallengeService({required this.stats});

  static const _challenges = [
    WeeklyChallenge('Tag 5 mistakes', 'mistakes', 5),
    WeeklyChallenge('Play 100 hands', 'hands', 100),
  ];

  int _index = 0;
  DateTime _start = DateTime.now();
  int _baseHands = 0;
  int _baseMistakes = 0;

  WeeklyChallenge get current => _challenges[_index];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _index = prefs.getInt(_indexKey) ?? 0;
    final startStr = prefs.getString(_startKey);
    _start = startStr != null ? DateTime.tryParse(startStr) ?? DateTime.now() : DateTime.now();
    _baseHands = prefs.getInt(_handsKey) ?? stats.handsReviewed;
    _baseMistakes = prefs.getInt(_mistakesKey) ?? stats.mistakesFixed;
    _rotate();
    stats.handsStream.listen((_) => _onStats());
    stats.mistakesStream.listen((_) => _onStats());
    notifyListeners();
  }

  int get progressValue {
    _rotate();
    switch (current.type) {
      case 'hands':
        return stats.handsReviewed - _baseHands;
      default:
        return stats.mistakesFixed - _baseMistakes;
    }
  }

  double get progress => (progressValue / current.target).clamp(0.0, 1.0);

  void _onStats() {
    _rotate();
    notifyListeners();
  }

  bool _rotate() {
    final now = DateTime.now();
    if (now.difference(_start).inDays >= 7) {
      _index = (_index + 1) % _challenges.length;
      _start = DateTime(now.year, now.month, now.day);
      _baseHands = stats.handsReviewed;
      _baseMistakes = stats.mistakesFixed;
      _save();
      return true;
    }
    return false;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_indexKey, _index);
    await prefs.setString(_startKey, _start.toIso8601String());
    await prefs.setInt(_handsKey, _baseHands);
    await prefs.setInt(_mistakesKey, _baseMistakes);
  }
}
