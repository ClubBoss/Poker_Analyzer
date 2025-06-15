import '../helpers/stack_manager.dart';
import '../models/action_entry.dart';

/// Service that manages stack sizes and investments based on actions.
class StackManagerService {
  final Map<int, int> _initialStacks;
  late StackManager _manager;
  final Map<int, int> stackSizes = {};

  Map<int, int> get initialStacks => Map<int, int>.from(_initialStacks);

  StackManagerService(Map<int, int> initialStacks, {Map<int, int>? remainingStacks})
      : _initialStacks = Map<int, int>.from(initialStacks) {
    _manager = StackManager(_initialStacks, remainingStacks: remainingStacks);
    stackSizes.addAll(_manager.currentStacks);
  }

  /// Re-initialize with a new set of initial stacks.
  void reset(Map<int, int> stacks, {Map<int, int>? remainingStacks}) {
    _initialStacks
      ..clear()
      ..addAll(stacks);
    _manager = StackManager(Map<int, int>.from(_initialStacks),
        remainingStacks: remainingStacks);
    stackSizes
      ..clear()
      ..addAll(_manager.currentStacks);
  }

  /// Update a single player's starting stack and reinitialize manager.
  void setInitialStack(int index, int stack, {Map<int, int>? remainingStacks}) {
    _initialStacks[index] = stack;
    _manager = StackManager(Map<int, int>.from(_initialStacks),
        remainingStacks: remainingStacks);
    stackSizes
      ..clear()
      ..addAll(_manager.currentStacks);
  }

  /// Remove a player from [_initialStacks] and reindex subsequent players.
  void removePlayer(int index) {
    final newStacks = <int, int>{};
    for (final entry in _initialStacks.entries) {
      if (entry.key < index) {
        newStacks[entry.key] = entry.value;
      } else if (entry.key > index) {
        newStacks[entry.key - 1] = entry.value;
      }
    }
    reset(newStacks);
  }

  /// Apply [actions] and update current stack sizes.
  void applyActions(List<ActionEntry> actions) {
    _manager.applyActions(actions);
    stackSizes
      ..clear()
      ..addAll(_manager.currentStacks);
  }

  int getStackForPlayer(int playerIndex) =>
      _manager.getStackForPlayer(playerIndex);

  int getInvestmentForStreet(int playerIndex, int street) =>
      _manager.getInvestmentForStreet(playerIndex, street);

  int getTotalInvested(int playerIndex) =>
      _manager.getTotalInvested(playerIndex);

  /// Calculates the effective stack size using [actions] visible up to the
  /// current point in the hand.
  int calculateEffectiveStack(int currentStreet, List<ActionEntry> actions) {
    int? minStack;
    for (final entry in stackSizes.entries) {
      final index = entry.key;
      final folded = actions.any((a) =>
          a.playerIndex == index && a.action == 'fold' && a.street <= currentStreet);
      if (folded) continue;
      final stack = entry.value;
      if (minStack == null || stack < minStack) {
        minStack = stack;
      }
    }
    return minStack ?? 0;
  }

  /// Calculates the effective stack size at the end of [street].
  int calculateEffectiveStackForStreet(
      int street, List<ActionEntry> visibleActions, int numberOfPlayers) {
    int? minStack;
    for (int index = 0; index < numberOfPlayers; index++) {
      final folded = visibleActions.any((a) =>
          a.playerIndex == index && a.action == 'fold' && a.street <= street);
      if (folded) continue;

      final initial = _initialStacks[index] ?? 0;
      int invested = 0;
      for (int s = 0; s <= street; s++) {
        invested += _manager.getInvestmentForStreet(index, s);
      }
      final remaining = initial - invested;

      if (minStack == null || remaining < minStack) {
        minStack = remaining;
      }
    }
    return minStack ?? 0;
  }

  /// Calculates effective stack sizes for every street.
  Map<String, int> calculateEffectiveStacksPerStreet(
      List<ActionEntry> actions, int numberOfPlayers) {
    const streetNames = ['Preflop', 'Flop', 'Turn', 'River'];
    final Map<String, int> stacks = {};
    for (int street = 0; street < streetNames.length; street++) {
      stacks[streetNames[street]] =
          calculateEffectiveStackForStreet(street, actions, numberOfPlayers);
    }
    return stacks;
  }
}
