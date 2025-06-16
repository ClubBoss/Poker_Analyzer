import '../helpers/pot_calculator.dart';
import '../models/action_entry.dart';
import '../models/street_investments.dart';
import 'stack_manager_service.dart';

/// Synchronizes pot sizes and provides effective stack calculations.
class PotSyncService {
  PotSyncService({
    PotCalculator? potCalculator,
    StackManagerService? stackService,
  })  : _potCalculator = potCalculator ?? PotCalculator(),
        _stackService = stackService;

  final PotCalculator _potCalculator;
  StackManagerService? _stackService;

  /// Current pot size for each street.
  final List<int> pots = List.filled(4, 0);

  set stackService(StackManagerService v) => _stackService = v;
  StackManagerService get stackService => _stackService!;

  /// Computes pot sizes for [actions] without mutating [pots].
  List<int> computePots(List<ActionEntry> actions) {
    final investments = StreetInvestments();
    for (final a in actions) {
      investments.addAction(a);
    }
    return _potCalculator.calculatePots(actions, investments);
  }

  /// Recompute [pots] based on visible [actions].
  void updatePots(List<ActionEntry> actions) {
    final p = computePots(actions);
    for (int i = 0; i < pots.length; i++) {
      pots[i] = p[i];
    }
  }

  /// Updates [pots] using only actions up to [playbackIndex].
  void updateForPlayback(int playbackIndex, List<ActionEntry> actions) {
    final subset = actions.take(playbackIndex).toList();
    updatePots(subset);
  }

  /// Calculates the effective stack size using [actions] visible up to the
  /// current point in the hand.
  int calculateEffectiveStack(int currentStreet, List<ActionEntry> actions) {
    int? minStack;
    for (final entry in stackService.stackSizes.entries) {
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

      final initial = stackService.initialStacks[index] ?? 0;
      int invested = 0;
      for (int s = 0; s <= street; s++) {
        invested += stackService.getInvestmentForStreet(index, s);
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
