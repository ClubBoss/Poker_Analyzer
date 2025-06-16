import '../helpers/stack_manager.dart';
import '../models/action_entry.dart';
import 'pot_sync_service.dart';

/// Service that manages stack sizes and investments based on actions.
class StackManagerService {
  final Map<int, int> _initialStacks;
  late StackManager _manager;
  final Map<int, int> stackSizes = {};
  final PotSyncService potSync;

  StackManagerService(Map<int, int> initialStacks,
      {required this.potSync, Map<int, int>? remainingStacks})
      : _initialStacks = Map<int, int>.from(initialStacks) {
    _manager = StackManager(_initialStacks, remainingStacks: remainingStacks);
    stackSizes.addAll(_manager.currentStacks);
    potSync.stackService = this;
  }

  /// Current initial stack sizes.
  Map<int, int> get initialStacks => Map<int, int>.from(_initialStacks);

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
    potSync.stackService = this;
  }

  /// Apply [actions] and update current stack sizes.
  void applyActions(List<ActionEntry> actions) {
    _manager.applyActions(actions);
    stackSizes
      ..clear()
      ..addAll(_manager.currentStacks);
    potSync.updatePots(actions);
  }

  int getStackForPlayer(int playerIndex) =>
      _manager.getStackForPlayer(playerIndex);

  int getInvestmentForStreet(int playerIndex, int street) =>
      _manager.getInvestmentForStreet(playerIndex, street);

  int getTotalInvested(int playerIndex) =>
      _manager.getTotalInvested(playerIndex);
}
