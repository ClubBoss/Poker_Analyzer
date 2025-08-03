import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import '../models/achievement_info.dart';
import '../models/simple_achievement.dart';
import '../widgets/achievement_unlocked_overlay.dart';
import '../services/training_stats_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/streak_service.dart';
import '../services/xp_tracker_service.dart';
import '../services/daily_learning_goal_service.dart';
import '../services/learning_path_progress_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/pack_library_loader_service.dart';
import '../main.dart';

class AchievementService extends ChangeNotifier {
  static AchievementService? _instance;
  static AchievementService get instance => _instance!;

  AchievementService({
    required this.stats,
    required this.hands,
    required this.streak,
    required this.dailyGoal,
    required this.mastery,
    required this.xp,
  }) {
    _instance = this;
    _init();
  }

  final TrainingStatsService stats;
  final SavedHandManagerService hands;
  final StreakService streak;
  final DailyLearningGoalService dailyGoal;
  final TagMasteryService mastery;
  final XPTrackerService xp;

  static const _key = 'simple_ach_';

  final List<SimpleAchievement> _achievements = [];

  List<SimpleAchievement> get achievements => List.unmodifiable(_achievements);

  DateTime? _parse(String? s) => s != null ? DateTime.tryParse(s) : null;

  Future<void> _init() async {
    final prefs = await PreferencesService.getInstance();
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
      SimpleAchievement(
        id: 'first_streak',
        title: 'Первый стрик',
        icon: Icons.local_fire_department,
        unlocked: prefs.getBool('${_key}first_streak') ?? false,
        date: _parse(prefs.getString('${_key}first_streak_date')),
      ),
      SimpleAchievement(
        id: 'first_level',
        title: 'Первый уровень',
        icon: Icons.school,
        unlocked: prefs.getBool('${_key}first_level') ?? false,
        date: _parse(prefs.getString('${_key}first_level_date')),
      ),
      SimpleAchievement(
        id: 'ev_expert',
        title: 'EV-эксперт',
        icon: Icons.percent,
        unlocked: prefs.getBool('${_key}ev_expert') ?? false,
        date: _parse(prefs.getString('${_key}ev_expert_date')),
      ),
      SimpleAchievement(
        id: 'tag_analyst',
        title: 'Покерный аналитик',
        icon: Icons.search,
        unlocked: prefs.getBool('${_key}tag_analyst') ?? false,
        date: _parse(prefs.getString('${_key}tag_analyst_date')),
      ),
      SimpleAchievement(
        id: 'first_training_done',
        title: 'Первая тренировка',
        icon: Icons.play_circle,
        unlocked: prefs.getBool('${_key}first_training_done') ?? false,
        date: _parse(prefs.getString('${_key}first_training_done_date')),
      ),
      SimpleAchievement(
        id: 'learning_path_3',
        title: '3 стадии пройдены',
        icon: Icons.grade,
        unlocked: prefs.getBool('${_key}learning_path_3') ?? false,
        date: _parse(prefs.getString('${_key}learning_path_3_date')),
      ),
      SimpleAchievement(
        id: 'beginner_master',
        title: 'Мастер Beginner',
        icon: Icons.workspace_premium,
        unlocked: prefs.getBool('${_key}beginner_master') ?? false,
        date: _parse(prefs.getString('${_key}beginner_master_date')),
      ),
      SimpleAchievement(
        id: 'path_completed',
        title: 'Путь завершён',
        icon: Icons.emoji_events,
        unlocked: prefs.getBool('${_key}path_completed') ?? false,
        date: _parse(prefs.getString('${_key}path_completed_date')),
      ),
    ]);
    stats.sessionsStream.listen((_) => checkAll());
    stats.handsStream.listen((_) => checkAll());
    streak.addListener(() => checkAll());
    dailyGoal.addListener(() => checkAll());
    checkAll();
  }

  Future<void> _save(SimpleAchievement a) async {
    final prefs = await PreferencesService.getInstance();
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

  /// Public wrapper to unlock an achievement by [id].
  Future<void> unlock(String id) => _unlock(id);

  /// Returns `true` if achievement with [id] has been unlocked.
  bool isUnlocked(String id) {
    final i = _achievements.indexWhere((a) => a.id == id);
    return i != -1 && _achievements[i].unlocked;
  }

  Future<void> checkAll() async {
    if (stats.sessionsCompleted > 0) await _unlock('first_pack');
    if (streak.streak.value >= 7) await _unlock('streak_7');
    if (stats.handsReviewed >= 100) await _unlock('hands_100');
    if (streak.errorFreeStreak >= 3) await _unlock('error_free_3');
    if (dailyGoal.streakCount >= 3) await _unlock('first_streak');
    await _checkFirstLevel();
    await _checkEvExpert();
    await _checkWeakTags();
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

  Future<void> _checkFirstLevel() async {
    final ach = _achievements.firstWhere((a) => a.id == 'first_level');
    if (ach.unlocked) return;
    final stages = await LearningPathProgressService.instance.getCurrentStageState();
    if (stages.isEmpty) return;
    final first = stages.first;
    final completed = LearningPathProgressService.instance.isStageCompleted(first.items);
    if (completed) await _unlock('first_level');
  }

  Future<void> _checkEvExpert() async {
    final ach = _achievements.firstWhere((a) => a.id == 'ev_expert');
    if (ach.unlocked) return;
    await PackLibraryLoaderService.instance.loadLibrary();
    for (final tpl in PackLibraryLoaderService.instance.library) {
      final stat = await TrainingPackStatsService.getStats(tpl.id);
      if (stat == null) continue;
      final pct = stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct;
      if (pct >= 90) {
        await _unlock('ev_expert');
        break;
      }
    }
  }

  Future<void> _checkWeakTags() async {
    final ach = _achievements.firstWhere((a) => a.id == 'tag_analyst');
    if (ach.unlocked) return;
    final weak = await mastery.topWeakTags(5);
    if (weak.isEmpty) return;
    await PackLibraryLoaderService.instance.loadLibrary();
    final byId = {for (final t in PackLibraryLoaderService.instance.library) t.id: t};
    int count = 0;
    for (final log in mastery.logs.logs) {
      final tpl = byId[log.templateId];
      if (tpl == null) continue;
      final tags = [for (final t in tpl.tags) t.toLowerCase()];
      if (tags.any((t) => weak.contains(t))) {
        count += 1;
      }
      if (count >= 5) break;
    }
    if (count >= 5) await _unlock('tag_analyst');
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
      AchievementInfo(
        id: 'first_streak',
        title: 'Первый стрик',
        description: 'Выполните цель 3 дня подряд',
        progress: dailyGoal.streakCount,
        thresholds: const [3],
        iconsPerLevel: const [Icons.local_fire_department],
        category: 'Streaks',
      ),
      AchievementInfo(
        id: 'first_level',
        title: 'Первый уровень',
        description: 'Завершите первый этап обучения',
        progress: unlocked['first_level'] == true ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.school],
        category: 'Learning',
      ),
      AchievementInfo(
        id: 'ev_expert',
        title: 'EV-эксперт',
        description: 'Достигните EV > 90% в паке',
        progress: unlocked['ev_expert'] == true ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.percent],
        category: 'Accuracy',
      ),
      AchievementInfo(
        id: 'tag_analyst',
        title: 'Покерный аналитик',
        description: 'Завершите 5 паков по слабым тегам',
        progress: unlocked['tag_analyst'] == true ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.search],
        category: 'Learning',
      ),
      AchievementInfo(
        id: 'first_training_done',
        title: 'Первая тренировка',
        description: 'Завершите любой тренировочный пак',
        progress: unlocked['first_training_done'] == true ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.play_circle],
        category: 'Learning',
      ),
      AchievementInfo(
        id: 'learning_path_3',
        title: '3 стадии пройдены',
        description: 'Завершите три стадии обучения',
        progress: unlocked['learning_path_3'] == true ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.grade],
        category: 'Learning',
      ),
      AchievementInfo(
        id: 'beginner_master',
        title: 'Мастер Beginner',
        description: 'Все паки уровня Beginner пройдены',
        progress: unlocked['beginner_master'] == true ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.workspace_premium],
        category: 'Learning',
      ),
      AchievementInfo(
        id: 'path_completed',
        title: 'Путь завершён',
        description: 'Завершите все стадии обучения',
        progress: unlocked['path_completed'] == true ? 1 : 0,
        thresholds: const [1],
        iconsPerLevel: const [Icons.emoji_events],
        category: 'Learning',
      ),
    ];
  }

}
