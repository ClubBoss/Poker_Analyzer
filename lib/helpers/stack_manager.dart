import '../models/action_entry.dart';

/// Manages stack recalculations based solely on actions.
class StackManager {
  final Map<int, int> _initialStacks;
  final Map<int, int> _currentStacks = {};

  StackManager(Map<int, int> initialStacks)
      : _initialStacks = Map<int, int>.from(initialStacks) {
    _currentStacks.addAll(_initialStacks);
  }

  /// Replays [actions] from the beginning and updates current stacks.
  void applyActions(List<ActionEntry> actions) {
    _currentStacks
      ..clear()
      ..addAll(_initialStacks);
    for (final a in actions) {
      if (a.action == 'call' || a.action == 'bet' || a.action == 'raise') {
        final amount = a.amount ?? 0;
        _currentStacks[a.playerIndex] =
            (_currentStacks[a.playerIndex] ?? 0) - amount;
      }
    }
  }

  /// The latest stack sizes after applying actions.
  Map<int, int> get currentStacks => _currentStacks;

  /// Returns the stack for a specific [playerIndex].
  int getStackForPlayer(int playerIndex) => _currentStacks[playerIndex] ?? 0;
}
