import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_info.dart';
import '../models/simple_achievement.dart';
import '../widgets/achievement_unlocked_overlay.dart';
import '../services/training_stats_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/streak_service.dart';
import '../services/xp_tracker_service.dart';
import '../main.dart';

class AchievementService extends ChangeNotifier {
  AchievementService({
    required this.stats,
    required this.hands,
    required this.streak,
    required this.xp,
  }) {
    _init();
  }

  final TrainingStatsService stats;
  final SavedHandManagerService hands;
  final StreakService streak;
  final XPTrackerService xp;

  static const _key = 'simple_ach_';

  final List<SimpleAchievement> _achievements = [];

  List<SimpleAchievement> get achievements => List.unmodifiable(_achievements);

  DateTime? _parse(String? s) => s != null ? DateTime.tryParse(s) : null;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _achievements.addAll([
      SimpleAchievement(
        id: 'first_pack',
        title: 'Первый пак завершён',
        icon: Icons.flag,
        unlocked: prefs.getBool('${_key}first_pack') ?? false,
        date: _parse(prefs.getString('${_key}first_pack_date')),
      ),
      SimpleAchievement(
        id: 'streak_7',
        title: '7 дней подряд',
        icon: Icons.local_fire_department,
        unlocked: prefs.getBool('${_key}streak_7') ?? false,
        date: _parse(prefs.getString('${_key}streak_7_date')),
      ),
      SimpleAchievement(
        id: 'hands_100',
        title: '100 рук сыграно',
        icon: Icons.pan_tool_alt,
        unlocked: prefs.getBool('${_key}hands_100') ?? false,
        date: _parse(prefs.getString('${_key}hands_100_date')),
      ),
      SimpleAchievement(
        id: 'ev_015',
        title: 'EV-мастер',
        icon: Icons.trending_up,
        unlocked: prefs.getBool('${_key}ev_015') ?? false,
        date: _parse(prefs.getString('${_key}ev_015_date')),
      ),
      SimpleAchievement(
        id: 'error_free_3',
        title: 'Без ошибок 3 дня',
        icon: Icons.check_circle,
        unlocked: prefs.getBool('${_key}error_free_3') ?? false,
        date: _parse(prefs.getString('${_key}error_free_3_date')),
      ),
    ]);
    stats.sessionsStream.listen((_) => _check());
    stats.handsStream.listen((_) => _check());
    streak.addListener(_check);
    _check();
  }

  Future<void> _save(SimpleAchievement a) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_key${a.id}', a.unlocked);
    if (a.date != null) {
      await prefs.setString('$_key${a.id}_date', a.date!.toIso8601String());
    }
  }

  Future<void> _unlock(String id) async {
    final i = _achievements.indexWhere((a) => a.id == id);
    if (i == -1) return;
    final a = _achievements[i];
    if (a.unlocked) return;
    final updated = a.copyWith(unlocked: true, date: DateTime.now());
    _achievements[i] = updated;
    await _save(updated);
    await xp.add(xp: XPTrackerService.achievementXp, source: 'achievement');
    final ctx = navigatorKey.currentState?.context;
    if (ctx != null) {
      showAchievementUnlockedOverlay(ctx, a.icon, a.title);
    }
    notifyListeners();
  }

  void _check() {
    if (stats.sessionsCompleted > 0) _unlock('first_pack');
    if (streak.streak.value >= 7) _unlock('streak_7');
    if (stats.handsReviewed >= 100) _unlock('hands_100');
    if (streak.errorFreeStreak >= 3) _unlock('error_free_3');
    _checkEv();
  }

  void _checkEv() {
    final ach = _achievements.firstWhere((a) => a.id == 'ev_015');
    if (ach.unlocked) return;
    if (hands.hands.isEmpty) return;
    final id = hands.hands.last.sessionId;
    final evs = <double>[];
    for (final h in hands.hands.where((e) => e.sessionId == id)) {
      final v = h.heroEv;
      if (v != null) evs.add(v);
    }
    if (evs.isEmpty) return;
    final avg = evs.reduce((a, b) => a + b) / evs.length;
    if (avg > 0.15) _unlock('ev_015');
  }
  List<AchievementInfo> allAchievements() {
    final unlocked = {for (final a in _achievements) a.id: a.unlocked};
    return [
      AchievementInfo(
        id: 'first_pack',
        title: 'Первый пак завершён',
        description: 'Завершите первую тренировку',
        progress: stats.sessionsCompleted > 0 ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.flag],
        category: 'Volume',
      ),
      AchievementInfo(
        id: 'hands_100',
        title: 'Руки разобраны',
        description: 'Разберите сыгранные руки',
        progress: stats.handsReviewed,
        thresholds: const [10, 50, 200, 1000],
        iconsPerLevel: const [
          Icons.looks_one,
          Icons.looks_two,
          Icons.looks_3,
          Icons.looks_4,
        ],
        category: 'Volume',
      ),
      AchievementInfo(
        id: 'streak_7',
        title: 'Дни подряд',
        description: 'Тренируйтесь каждый день',
        progress: streak.streak.value,
        thresholds: const [3, 7, 30, 100],
        iconsPerLevel: const [
          Icons.calendar_view_day,
          Icons.calendar_today,
          Icons.calendar_month,
          Icons.event_available,
        ],
        category: 'Streaks',
      ),
      AchievementInfo(
        id: 'error_free_3',
        title: 'Без ошибок',
        description: 'Дни без ошибок',
        progress: streak.errorFreeStreak,
        thresholds: const [1, 3, 7, 30],
        iconsPerLevel: const [
          Icons.check,
          Icons.check_circle,
          Icons.check_circle_outline,
          Icons.verified,
        ],
        category: 'Streaks',
      ),
      AchievementInfo(
        id: 'ev_015',
        title: 'EV-мастер',
        description: 'Средний EV > 0.15 в сессии',
        progress: unlocked['ev_015'] == true ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.trending_up],
        category: 'Accuracy',
      ),
    ];
  }

}
