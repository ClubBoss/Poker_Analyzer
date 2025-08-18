import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement_basic.dart';
import '../widgets/achievement_dialog.dart';
import '../widgets/achievement_reward_popup.dart';
import '../services/xp_tracker_service.dart';
import '../services/coins_service.dart';
import '../services/training_stats_service.dart';
import '../services/streak_tracker_service.dart';
import '../main.dart';

/// Engine that unlocks basic achievements based on user progress.
class AchievementsEngine extends ChangeNotifier {
  static AchievementsEngine? _instance;
  static AchievementsEngine get instance => _instance!;

  final XPTrackerService xp;
  final TrainingStatsService stats;
  final StreakTrackerService streak;

  factory AchievementsEngine({
    required XPTrackerService xp,
    required TrainingStatsService stats,
    required StreakTrackerService streak,
  }) {
    return _instance ??= AchievementsEngine._(xp, stats, streak);
  }

  AchievementsEngine._(this.xp, this.stats, this.streak) {
    _init();
  }

  static const _pref = 'ach_engine_';

  final List<AchievementBasic> _achievements = [];
  List<AchievementBasic> get achievements => List.unmodifiable(_achievements);

  DateTime? _parse(String? s) => s != null ? DateTime.tryParse(s) : null;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _achievements.addAll([
      AchievementBasic(
        id: 'first_xp',
        title: 'Первый XP',
        description: 'Получите 1 XP',
        isUnlocked: prefs.getBool('${_pref}first_xp') ?? false,
        unlockDate: _parse(prefs.getString('${_pref}first_xp_date')),
        rewardXp: XPTrackerService.achievementXp,
      ),
      AchievementBasic(
        id: 'first_level',
        title: 'Первый уровень',
        description: 'Достигните уровня 1',
        isUnlocked: prefs.getBool('${_pref}first_level') ?? false,
        unlockDate: _parse(prefs.getString('${_pref}first_level_date')),
        rewardXp: XPTrackerService.achievementXp,
      ),
      AchievementBasic(
        id: 'ten_packs',
        title: '10 паков',
        description: 'Завершите 10 паков',
        isUnlocked: prefs.getBool('${_pref}ten_packs') ?? false,
        unlockDate: _parse(prefs.getString('${_pref}ten_packs_date')),
        rewardXp: XPTrackerService.achievementXp,
      ),
      AchievementBasic(
        id: 'weekly_streak',
        title: '7-дневный стрик',
        description: 'Поддерживайте стрик 7 дней',
        isUnlocked: prefs.getBool('${_pref}weekly_streak') ?? false,
        unlockDate: _parse(prefs.getString('${_pref}weekly_streak_date')),
        rewardXp: XPTrackerService.achievementXp,
      ),
      AchievementBasic(
        id: 'first_mistake_review',
        title: 'Первая повтор ошибок',
        description: 'Используйте повтор ошибок',
        isUnlocked: prefs.getBool('${_pref}first_mistake_review') ?? false,
        unlockDate: _parse(
          prefs.getString('${_pref}first_mistake_review_date'),
        ),
        rewardXp: XPTrackerService.achievementXp,
      ),
    ]);
    xp.addListener(() => unawaited(checkAll()));
    stats.sessionsStream.listen((_) => unawaited(checkAll()));
    checkAll();
  }

  Future<void> _save(AchievementBasic a) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_pref${a.id}', a.isUnlocked);
    if (a.unlockDate != null) {
      await prefs.setString(
        '$_pref${a.id}_date',
        a.unlockDate!.toIso8601String(),
      );
    }
  }

  Future<void> _unlock(String id) async {
    final i = _achievements.indexWhere((a) => a.id == id);
    if (i == -1) return;
    final a = _achievements[i];
    if (a.isUnlocked) return;
    final updated = a.copyWith(isUnlocked: true, unlockDate: DateTime.now());
    _achievements[i] = updated;
    await _save(updated);
    if (updated.rewardXp > 0) {
      await xp.add(xp: updated.rewardXp, source: 'achievement');
    }
    if (updated.rewardCoins > 0) {
      await CoinsService.instance.addCoins(updated.rewardCoins);
    }
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      if (updated.showRewardPopup) {
        showAchievementRewardPopup(
          ctx,
          icon: Icons.emoji_events,
          title: updated.title,
          xp: updated.rewardXp,
          coins: updated.rewardCoins,
        );
      } else {
        await showAchievementDialog(ctx, updated);
      }
    }
    notifyListeners();
  }

  Future<void> checkAll() async {
    if (xp.xp >= 1) await _unlock('first_xp');
    if (xp.level >= 1) await _unlock('first_level');
    if (stats.sessionsCompleted >= 10) await _unlock('ten_packs');
    final currentStreak = await streak.getCurrentStreak();
    if (currentStreak >= 7) await _unlock('weekly_streak');
    // check first mistake review using GoalsService progress
    // If user reviewed at least one mistake, GoalsService stores progress
    final prefs = await SharedPreferences.getInstance();
    final reviewed = prefs.getInt('mistake_review_progress') ?? 0;
    if (reviewed > 0) await _unlock('first_mistake_review');
  }
}
