// Helper utilities for working with ActionEntry lists.
import '../models/action_entry.dart';

/// Returns true if [action] was performed by the hero at [heroIndex].
bool isHeroAction(ActionEntry action, int heroIndex) {
  return action.playerIndex == heroIndex;
}

/// Returns true if [action] was performed by an opponent of the hero.
bool isOpponentAction(ActionEntry action, int heroIndex) {
  return action.playerIndex != heroIndex;
}

/// Filters [actions] to only those taken by opponents of the hero.
List<ActionEntry> actionsAgainstHero(List<ActionEntry> actions, int heroIndex) {
  return actions.where((a) => isOpponentAction(a, heroIndex)).toList();
}
