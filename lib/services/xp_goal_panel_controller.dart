import '../models/xp_guided_goal.dart';

/// Manages XP goals displayed in the goal panel UI.
class XpGoalPanelController {
  XpGoalPanelController();

  static final XpGoalPanelController instance = XpGoalPanelController();

  final List<XPGuidedGoal> _goals = [];

  /// Returns an unmodifiable list of panel goals.
  List<XPGuidedGoal> get goals => List.unmodifiable(_goals);

  /// Adds [goal] if not already present.
  void addGoal(XPGuidedGoal goal) {
    if (_goals.any((g) => g.id == goal.id)) return;
    _goals.add(goal);
  }

  /// Removes goal with [id] if it exists.
  void removeGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
  }

  /// Clears all panel goals.
  void clear() {
    _goals.clear();
  }
}
