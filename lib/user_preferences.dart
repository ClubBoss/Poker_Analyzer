import 'package:flutter/material.dart';
import 'services/user_preferences_service.dart';
import 'services/theme_service.dart';

class UserPreferences {
  UserPreferences._(this.service, this.theme);

  static late final UserPreferences instance;

  final UserPreferencesService service;
  final ThemeService theme;

  static void init(UserPreferencesService service, ThemeService theme) {
    instance = UserPreferences._(service, theme);
  }

  bool get showPotAnimation => service.showPotAnimation;
  bool get showCardReveal => service.showCardReveal;
  bool get showWinnerCelebration => service.showWinnerCelebration;
  bool get showActionHints => service.showActionHints;
  bool get coachMode => service.coachMode;
  bool get demoMode => service.demoMode;
  bool get tutorialCompleted => service.tutorialCompleted;
  bool get simpleNavigation => service.simpleNavigation;
  bool get showTagGoalBanner => service.showTagGoalBanner;
  Color get accentColor => theme.accentColor;

  Future<void> setShowPotAnimation(bool value) => service.setShowPotAnimation(value);
  Future<void> setShowCardReveal(bool value) => service.setShowCardReveal(value);
  Future<void> setShowWinnerCelebration(bool value) => service.setShowWinnerCelebration(value);
  Future<void> setShowActionHints(bool value) => service.setShowActionHints(value);
  Future<void> setCoachMode(bool value) => service.setCoachMode(value);
  Future<void> setDemoMode(bool value) => service.setDemoMode(value);
  Future<void> setSimpleNavigation(bool value) => service.setSimpleNavigation(value);
  Future<void> setTutorialCompleted(bool value) => service.setTutorialCompleted(value);
  Future<void> setShowTagGoalBanner(bool value) => service.setShowTagGoalBanner(value);
  Future<void> setAccentColor(Color value) => theme.setAccentColor(value);
}
