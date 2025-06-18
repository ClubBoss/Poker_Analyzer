import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService extends ChangeNotifier {
  static const _potAnimationKey = 'show_pot_animation';
  static const _cardRevealKey = 'show_card_reveal';
  static const _winnerCelebrationKey = 'show_winner_celebration';
  static const _actionHintsKey = 'show_action_hints';

  bool _showPotAnimation = true;
  bool _showCardReveal = true;
  bool _showWinnerCelebration = true;
  bool _showActionHints = true;

  bool get showPotAnimation => _showPotAnimation;
  bool get showCardReveal => _showCardReveal;
  bool get showWinnerCelebration => _showWinnerCelebration;
  bool get showActionHints => _showActionHints;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _showPotAnimation = prefs.getBool(_potAnimationKey) ?? true;
    _showCardReveal = prefs.getBool(_cardRevealKey) ?? true;
    _showWinnerCelebration = prefs.getBool(_winnerCelebrationKey) ?? true;
    _showActionHints = prefs.getBool(_actionHintsKey) ?? true;
    notifyListeners();
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
}
