import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';

class UserPreferencesService extends ChangeNotifier {
  static const _potAnimationKey = 'show_pot_animation';
  static const _cardRevealKey = 'show_card_reveal';
  static const _winnerCelebrationKey = 'show_winner_celebration';
  static const _actionHintsKey = 'show_action_hints';
  static const _coachModeKey = 'coach_mode';
  static const _demoModeKey = 'demo_mode';
  static const _tutorialCompletedKey = 'tutorial_completed';
  static const _simpleNavKey = 'simple_navigation';
  static const _weakRangeStartKey = 'weak_range_start';
  static const _weakRangeEndKey = 'weak_range_end';
  static const _weakCatCountKey = 'weak_cat_count';
  static const _evRangeStartKey = 'ev_range_start';
  static const _evRangeEndKey = 'ev_range_end';
  static const _tagGoalBannerKey = 'show_tag_goal_banner';

  bool _showPotAnimation = true;
  bool _showCardReveal = true;
  bool _showWinnerCelebration = true;
  bool _showActionHints = true;
  bool _coachMode = false;
  bool _demoMode = false;
  bool _tutorialCompleted = false;
  bool _simpleNavigation = false;
  DateTimeRange? _weakRange;
  int _weakCatCount = 5;
  RangeValues _evRange = const RangeValues(0, 5);
  bool _showTagGoalBanner = true;
  final CloudSyncService? cloud;

  UserPreferencesService({this.cloud});

  bool get showPotAnimation => _showPotAnimation;
  bool get showCardReveal => _showCardReveal;
  bool get showWinnerCelebration => _showWinnerCelebration;
  bool get showActionHints => _showActionHints;
  bool get coachMode => _coachMode;
  bool get demoMode => _demoMode;
  bool get tutorialCompleted => _tutorialCompleted;
  bool get simpleNavigation => _simpleNavigation;
  DateTimeRange? get weaknessRange => _weakRange;
  int get weaknessCategoryCount => _weakCatCount;
  RangeValues get evRange => _evRange;
  bool get showTagGoalBanner => _showTagGoalBanner;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _showPotAnimation = prefs.getBool(_potAnimationKey) ?? true;
    _showCardReveal = prefs.getBool(_cardRevealKey) ?? true;
    _showWinnerCelebration = prefs.getBool(_winnerCelebrationKey) ?? true;
    _showActionHints = prefs.getBool(_actionHintsKey) ?? true;
    _coachMode = prefs.getBool(_coachModeKey) ?? false;
    _demoMode = prefs.getBool(_demoModeKey) ?? false;
    _tutorialCompleted = prefs.getBool(_tutorialCompletedKey) ?? false;
    _simpleNavigation = prefs.getBool(_simpleNavKey) ?? false;
    _showTagGoalBanner = prefs.getBool(_tagGoalBannerKey) ?? true;
    final startStr = prefs.getString(_weakRangeStartKey);
    final endStr = prefs.getString(_weakRangeEndKey);
    if (startStr != null && endStr != null) {
      final s = DateTime.tryParse(startStr);
      final e = DateTime.tryParse(endStr);
      if (s != null && e != null) _weakRange = DateTimeRange(start: s, end: e);
    }
    final evStart = prefs.getDouble(_evRangeStartKey);
    final evEnd = prefs.getDouble(_evRangeEndKey);
    if (evStart != null && evEnd != null) {
      _evRange = RangeValues(evStart, evEnd);
    }
    _weakCatCount = prefs.getInt(_weakCatCountKey) ?? 5;
    notifyListeners();
  }

  Map<String, dynamic> _toMap() => {
        'showPotAnimation': _showPotAnimation,
        'showCardReveal': _showCardReveal,
        'showWinnerCelebration': _showWinnerCelebration,
        'showActionHints': _showActionHints,
        'coachMode': _coachMode,
        'demoMode': _demoMode,
        'tutorialCompleted': _tutorialCompleted,
        'simpleNavigation': _simpleNavigation,
        'showTagGoalBanner': _showTagGoalBanner,
        if (_weakRange != null) 'weakRangeStart': _weakRange!.start.toIso8601String(),
        if (_weakRange != null) 'weakRangeEnd': _weakRange!.end.toIso8601String(),
        'evRangeStart': _evRange.start,
        'evRangeEnd': _evRange.end,
        'weakCatCount': _weakCatCount,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (cloud != null) {
      final data = _toMap();
      await cloud!.queueMutation('preferences', 'main', data);
      unawaited(cloud!.syncUp());
    }
  }

  Future<void> _setBool(
      String key, bool current, bool value, void Function(bool) assign) async {
    if (current == value) return;
    assign(value);
    await _save(key, value);
    notifyListeners();
  }

  Future<void> setShowPotAnimation(bool value) =>
      _setBool(_potAnimationKey, _showPotAnimation, value,
          (v) => _showPotAnimation = v);

  Future<void> setShowCardReveal(bool value) =>
      _setBool(_cardRevealKey, _showCardReveal, value,
          (v) => _showCardReveal = v);

  Future<void> setShowWinnerCelebration(bool value) =>
      _setBool(_winnerCelebrationKey, _showWinnerCelebration, value,
          (v) => _showWinnerCelebration = v);

  Future<void> setShowActionHints(bool value) =>
      _setBool(_actionHintsKey, _showActionHints, value,
          (v) => _showActionHints = v);

  Future<void> setCoachMode(bool value) =>
      _setBool(_coachModeKey, _coachMode, value, (v) => _coachMode = v);

  Future<void> setDemoMode(bool value) =>
      _setBool(_demoModeKey, _demoMode, value, (v) => _demoMode = v);

  Future<void> setSimpleNavigation(bool value) =>
      _setBool(_simpleNavKey, _simpleNavigation, value,
          (v) => _simpleNavigation = v);

  Future<void> setTutorialCompleted(bool value) =>
      _setBool(_tutorialCompletedKey, _tutorialCompleted, value,
          (v) => _tutorialCompleted = v);

  Future<void> setWeaknessRange(DateTimeRange? value) async {
    _weakRange = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_weakRangeStartKey);
      await prefs.remove(_weakRangeEndKey);
    } else {
      await prefs.setString(_weakRangeStartKey, value.start.toIso8601String());
      await prefs.setString(_weakRangeEndKey, value.end.toIso8601String());
    }
    if (cloud != null) {
      final data = _toMap();
      await cloud!.queueMutation('preferences', 'main', data);
      unawaited(cloud!.syncUp());
    }
    notifyListeners();
  }

  Future<void> setWeaknessCategoryCount(int value) async {
    _weakCatCount = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weakCatCountKey, value);
    if (cloud != null) {
      final data = _toMap();
      await cloud!.queueMutation('preferences', 'main', data);
      unawaited(cloud!.syncUp());
    }
    notifyListeners();
  }

  Future<void> setEvRange(RangeValues value) async {
    _evRange = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_evRangeStartKey, value.start);
    await prefs.setDouble(_evRangeEndKey, value.end);
    if (cloud != null) {
      final data = _toMap();
      await cloud!.queueMutation('preferences', 'main', data);
      unawaited(cloud!.syncUp());
    }
    notifyListeners();
  }

  Future<void> setShowTagGoalBanner(bool value) =>
      _setBool(_tagGoalBannerKey, _showTagGoalBanner, value,
          (v) => _showTagGoalBanner = v);
}
