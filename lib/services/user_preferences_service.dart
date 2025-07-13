import 'dart:async';
import 'package:flutter/foundation.dart';
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
    final startStr = prefs.getString(_weakRangeStartKey);
    final endStr = prefs.getString(_weakRangeEndKey);
    if (startStr != null && endStr != null) {
      final s = DateTime.tryParse(startStr);
      final e = DateTime.tryParse(endStr);
      if (s != null && e != null) _weakRange = DateTimeRange(start: s, end: e);
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
        if (_weakRange != null) 'weakRangeStart': _weakRange!.start.toIso8601String(),
        if (_weakRange != null) 'weakRangeEnd': _weakRange!.end.toIso8601String(),
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
}
