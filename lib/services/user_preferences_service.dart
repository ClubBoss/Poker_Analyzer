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
    _showPotAnimation = _boolPref(prefs, _potAnimationKey, true);
    _showCardReveal = _boolPref(prefs, _cardRevealKey, true);
    _showWinnerCelebration = _boolPref(prefs, _winnerCelebrationKey, true);
    _showActionHints = _boolPref(prefs, _actionHintsKey, true);
    _coachMode = _boolPref(prefs, _coachModeKey, false);
    _demoMode = _boolPref(prefs, _demoModeKey, false);
    _tutorialCompleted = _boolPref(prefs, _tutorialCompletedKey, false);
    _simpleNavigation = _boolPref(prefs, _simpleNavKey, false);
    _showTagGoalBanner = _boolPref(prefs, _tagGoalBannerKey, true);
    final startStr = prefs.getString(_weakRangeStartKey);
    final endStr = prefs.getString(_weakRangeEndKey);
    if (startStr != null && endStr != null) {
      final s = DateTime.tryParse(startStr);
      final e = DateTime.tryParse(endStr);
      if (s != null && e != null) _weakRange = DateTimeRange(start: s, end: e);
    }
    _evRange = RangeValues(
      _doublePref(prefs, _evRangeStartKey, _evRange.start),
      _doublePref(prefs, _evRangeEndKey, _evRange.end),
    );
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

  Future<void> setShowPotAnimation(bool value) async {
    if (_showPotAnimation == value) return;
    _showPotAnimation = value;
    await _save(_potAnimationKey, value);
    notifyListeners();
  }

  Future<void> setShowCardReveal(bool value) async {
    if (_showCardReveal == value) return;
    _showCardReveal = value;
    await _save(_cardRevealKey, value);
    notifyListeners();
  }

  Future<void> setShowWinnerCelebration(bool value) async {
    if (_showWinnerCelebration == value) return;
    _showWinnerCelebration = value;
    await _save(_winnerCelebrationKey, value);
    notifyListeners();
  }

  Future<void> setShowActionHints(bool value) async {
    if (_showActionHints == value) return;
    _showActionHints = value;
    await _save(_actionHintsKey, value);
    notifyListeners();
  }

  Future<void> setCoachMode(bool value) async {
    if (_coachMode == value) return;
    _coachMode = value;
    await _save(_coachModeKey, value);
    notifyListeners();
  }

  Future<void> setDemoMode(bool value) async {
    if (_demoMode == value) return;
    _demoMode = value;
    await _save(_demoModeKey, value);
    notifyListeners();
  }

  Future<void> setSimpleNavigation(bool value) async {
    if (_simpleNavigation == value) return;
    _simpleNavigation = value;
    await _save(_simpleNavKey, value);
    notifyListeners();
  }

  Future<void> setTutorialCompleted(bool value) async {
    if (_tutorialCompleted == value) return;
    _tutorialCompleted = value;
    await _save(_tutorialCompletedKey, value);
    notifyListeners();
  }

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

  Future<void> setShowTagGoalBanner(bool value) async {
    if (_showTagGoalBanner == value) return;
    _showTagGoalBanner = value;
    await _save(_tagGoalBannerKey, value);
    notifyListeners();
  }
}

bool _boolPref(SharedPreferences prefs, String key, bool defaultValue) =>
    prefs.getBool(key) ?? defaultValue;

double _doublePref(SharedPreferences prefs, String key, double defaultValue) =>
    prefs.getDouble(key) ?? defaultValue;
