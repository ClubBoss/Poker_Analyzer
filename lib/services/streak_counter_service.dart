import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../widgets/confetti_overlay.dart';
import 'reward_system_service.dart';
import '../models/achievement_progress.dart';
import '../main.dart';
import 'training_stats_service.dart';
import 'daily_target_service.dart';
import 'xp_tracker_service.dart';

class StreakCounterService extends ChangeNotifier {
  static const _countKey = 'target_streak_count';
  static const _lastKey = 'target_streak_last';
  static const _maxKey = 'target_streak_max';
  static const _rewardKey = 'streak_reward_level';

  final TrainingStatsService stats;
  final DailyTargetService target;
  final XPTrackerService xp;

  int _count = 0;
  DateTime? _last;
  int _max = 0;
  int _rewardLevel = 0;

  final _recordController = StreamController<int>.broadcast();

  Stream<int> get recordStream => _recordController.stream;

  int get count => _count;
  DateTime? get lastSuccess => _last;
  int get max => _max;

  StreakCounterService(
      {required this.stats, required this.target, required this.xp}) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _count = prefs.getInt(_countKey) ?? 0;
    _max = prefs.getInt(_maxKey) ?? 0;
    final lastStr = prefs.getString(_lastKey);
    _last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    _rewardLevel = prefs.getInt(_rewardKey) ?? 0;
    await _updateForToday();
    stats.handsStream.listen((_) => _checkToday());
    target.addListener(_checkToday);
    _checkToday();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, _count);
    await prefs.setInt(_maxKey, _max);
    await prefs.setInt(_rewardKey, _rewardLevel);
    if (_last != null) {
      await prefs.setString(_lastKey, _last!.toIso8601String());
    } else {
      await prefs.remove(_lastKey);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _checkAndApplyStreakReward() async {
    final Map<int, int> thresholds = {3: 1, 7: 2, 14: 3, 30: 4};
    final level = thresholds[_count];
    if (level != null && level > _rewardLevel) {
      _rewardLevel = level;
      await RewardSystemService.instance
          .applyAchievementReward(AchievementProgress(level));
      await _save();
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        showConfettiOverlay(ctx);
        final xp = level * 50;
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
              content: Text('🔥 Вы достигли $_count-дневной цепочки! +$xp XP')),
        );
      }
    }
  }

  Future<void> _incrementStreak() async {
    _count += 1;
    if (_count > _max) {
      _max = _count;
      _recordController.add(_max);
    }
    await _checkAndApplyStreakReward();
  }

  Future<void> _updateForToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_last != null) {
      final lastDay = DateTime(_last!.year, _last!.month, _last!.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        await _incrementStreak();
      } else if (diff > 1) {
        _count = 0;
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> _checkToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hands = stats.handsPerDay[today] ?? 0;
    if (hands >= target.target &&
        (_last == null || !_isSameDay(_last!, today))) {
      _last = today;
      await _save();
      await xp.add(xp: XPTrackerService.targetXp, source: 'daily_target');
    }
  }

  Future<void> restart() async {
    _count = 0;
    _last = null;
    await _save();
    notifyListeners();
  }

  @override
  void dispose() {
    target.removeListener(_checkToday);
    _recordController.close();
    super.dispose();
  }
}
