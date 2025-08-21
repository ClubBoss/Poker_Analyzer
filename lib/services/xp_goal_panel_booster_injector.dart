import 'booster_goal_service.dart';
import 'xp_goal_panel_controller.dart';

/// Injects booster XP goals into [XpGoalPanelController].
class XpGoalPanelBoosterInjector {
  final BoosterGoalService booster;
  final XpGoalPanelController panel;

  XpGoalPanelBoosterInjector({
    BoosterGoalService? booster,
    XpGoalPanelController? panel,
  })  : booster = booster ?? BoosterGoalService.instance,
        panel = panel ?? XpGoalPanelController.instance;

  static final XpGoalPanelBoosterInjector instance =
      XpGoalPanelBoosterInjector();

  /// Fetches booster goals and injects them into the XP goal panel.
  void inject({int maxGoals = 2}) {
    final goals = booster.getGoals(maxGoals: maxGoals);
    for (final g in goals) {
      if (panel.goals.any((e) => e.id == g.id)) continue;
      panel.addGoal(g);
    }
  }
}
