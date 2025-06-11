import '../models/action_entry.dart';
import 'stack_with_investments.dart';

/// Manages stack recalculations based solely on actions.
class StackManager {
  final Map<int, int> _initialStacks;
  final Map<int, StackWithInvestments> _currentStacks = {};

  StackManager(Map<int, int> initialStacks)
      : _initialStacks = Map<int, int>.from(initialStacks) {
    for (final entry in _initialStacks.entries) {
      _currentStacks[entry.key] = StackWithInvestments(entry.value);
    }
  }

  /// Replays [actions] from the beginning and updates current stacks.
  void applyActions(List<ActionEntry> actions) {
    for (final sw in _currentStacks.values) {
      sw.clear();
    }
    for (final a in actions) {
      if (a.action == 'call' || a.action == 'bet' || a.action == 'raise') {
        final amount = a.amount;
        if (amount != null) {
          _currentStacks[a.playerIndex]?.addInvestment(a.street, amount);
        }
      }
    }
  }

  /// The latest stack sizes after applying actions.
  Map<int, int> get currentStacks =>
      _currentStacks.map((key, value) => MapEntry(key, value.remainingStack));

  /// Returns the stack for a specific [playerIndex].
  int getStackForPlayer(int playerIndex) =>
      _currentStacks[playerIndex]?.remainingStack ?? 0;
}
