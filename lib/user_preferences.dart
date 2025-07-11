import 'services/user_preferences_service.dart';

class UserPreferences {
  UserPreferences._(this.service);

  static late final UserPreferences instance;

  final UserPreferencesService service;

  static void init(UserPreferencesService service) {
    instance = UserPreferences._(service);
  }

  bool get showPotAnimation => service.showPotAnimation;
  bool get showCardReveal => service.showCardReveal;
  bool get showWinnerCelebration => service.showWinnerCelebration;
  bool get showActionHints => service.showActionHints;
  bool get coachMode => service.coachMode;
  bool get demoMode => service.demoMode;
  bool get tutorialCompleted => service.tutorialCompleted;
  bool get simpleNavigation => service.simpleNavigation;

  Future<void> setShowPotAnimation(bool value) => service.setShowPotAnimation(value);
  Future<void> setShowCardReveal(bool value) => service.setShowCardReveal(value);
  Future<void> setShowWinnerCelebration(bool value) => service.setShowWinnerCelebration(value);
  Future<void> setShowActionHints(bool value) => service.setShowActionHints(value);
  Future<void> setCoachMode(bool value) => service.setCoachMode(value);
  Future<void> setDemoMode(bool value) => service.setDemoMode(value);
  Future<void> setSimpleNavigation(bool value) => service.setSimpleNavigation(value);
  Future<void> setTutorialCompleted(bool value) => service.setTutorialCompleted(value);
}
