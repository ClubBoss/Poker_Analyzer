import 'package:flutter/foundation.dart';

import '../helpers/stack_manager.dart';
import '../models/action_entry.dart';
import 'pot_sync_service.dart';

/// Service that manages stack sizes and investments based on actions.
class StackManagerService extends ChangeNotifier {
  final Map<int, int> _initialStacks;
  late StackManager _manager;
  final Map<int, int> stackSizes = {};
  final PotSyncService potSync;

  StackManagerService(
    Map<int, int> initialStacks, {
    required this.potSync,
    Map<int, int>? remainingStacks,
  }) : _initialStacks = Map<int, int>.from(initialStacks) {
    _manager = StackManager(_initialStacks, remainingStacks: remainingStacks);
    stackSizes.addAll(_manager.currentStacks);
    potSync.stackService = this;
  }

  /// Current initial stack sizes.
  Map<int, int> get initialStacks => Map<int, int>.from(_initialStacks);

  /// Current stacks after applying actions.
  Map<int, int> get currentStacks => Map<int, int>.from(stackSizes);

  /// Initial stack for a specific player.
  int getInitialStack(int playerIndex) => _initialStacks[playerIndex] ?? 0;

  /// Re-initialize with a new set of initial stacks.
  void reset(Map<int, int> stacks, {Map<int, int>? remainingStacks}) {
    _initialStacks
      ..clear()
      ..addAll(stacks);
    _manager = StackManager(
      Map<int, int>.from(_initialStacks),
      remainingStacks: remainingStacks,
    );
    stackSizes
      ..clear()
      ..addAll(_manager.currentStacks);
    potSync.stackService = this;
    notifyListeners();
  }

  /// Apply [actions] and update current stack sizes.
  void applyActions(List<ActionEntry> actions) {
    _manager.applyActions(actions);
    stackSizes
      ..clear()
      ..addAll(_manager.currentStacks);
    potSync.updatePots(actions);
    notifyListeners();
  }

  /// Update the initial stack for [playerIndex].
  void setInitialStack(int playerIndex, int stack) {
    _initialStacks[playerIndex] = stack;
    _manager = StackManager(Map<int, int>.from(_initialStacks));
    stackSizes
      ..clear()
      ..addAll(_manager.currentStacks);
    notifyListeners();
  }

  /// Remove a player and shift subsequent stack entries.
  void removePlayer(int index) {
    final updated = <int, int>{};
    for (final entry in _initialStacks.entries) {
      if (entry.key < index) {
        updated[entry.key] = entry.value;
      } else if (entry.key > index) {
        updated[entry.key - 1] = entry.value;
      }
    }
    _initialStacks
      ..clear()
      ..addAll(updated);
    _manager = StackManager(Map<int, int>.from(_initialStacks));
    stackSizes
      ..clear()
      ..addAll(_manager.currentStacks);
    notifyListeners();
  }

  int getStackForPlayer(int playerIndex) =>
      _manager.getStackForPlayer(playerIndex);

  int getInvestmentForStreet(int playerIndex, int street) =>
      _manager.getInvestmentForStreet(playerIndex, street);

  int getTotalInvested(int playerIndex) =>
      _manager.getTotalInvested(playerIndex);
}
