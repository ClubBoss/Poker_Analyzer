import '../models/action_entry.dart';
import 'stack_with_investments.dart';

const Set<String> investmentActions = {'call', 'bet', 'raise', 'all-in'};

/// Manages stack recalculations based solely on actions.
class StackManager {
  final Map<int, int> _initialStacks;
  final Map<int, StackWithInvestments> _currentStacks = {};

  StackManager(Map<int, int> initialStacks, {Map<int, int>? remainingStacks})
      : _initialStacks = Map<int, int>.from(initialStacks) {
    for (final MapEntry<int, int> entry in _initialStacks.entries) {
      final StackWithInvestments sw = StackWithInvestments(entry.value);
      final int? remaining = remainingStacks?[entry.key];
      if (remaining != null && remaining < entry.value) {
        sw.addInvestment(0, entry.value - remaining);
      }
      _currentStacks[entry.key] = sw;
    }
  }

  /// Replays [actions] from the beginning and updates current stacks.
  void applyActions(List<ActionEntry> actions) {
    _resetInvestments();
    for (final ActionEntry a in actions) {
      _applyInvestment(a);
    }
  }

  void _resetInvestments() {
    for (final StackWithInvestments sw in _currentStacks.values) {
      sw.clear();
    }
  }

  void _applyInvestment(ActionEntry a) {
    if (investmentActions.contains(a.action)) {
      final double? amount = a.amount;
      if (amount != null) {
        _currentStacks[a.playerIndex]?.addInvestment(a.street, amount.round());
      }
    }
  }

  /// The latest stack sizes after applying actions.
  Map<int, int> get currentStacks =>
      _currentStacks.map((key, value) => MapEntry(key, value.remainingStack));

  /// Returns the stack for a specific [playerIndex].
  int getStackForPlayer(int playerIndex) =>
      _currentStacks[playerIndex]?.remainingStack ?? 0;

  /// Returns the chips invested by [playerIndex] on [street].
  int getInvestmentForStreet(int playerIndex, int street) =>
      _currentStacks[playerIndex]?.getInvestmentForStreet(street) ?? 0;

  /// Returns total chips invested by [playerIndex] across all streets.
  int getTotalInvested(int playerIndex) {
    final StackWithInvestments? sw = _currentStacks[playerIndex];
    if (sw == null) return 0;
    return sw.initialStack - sw.remainingStack;
  }
}
