import 'package:flutter/foundation.dart';

import '../helpers/pot_calculator.dart';
import '../models/action_entry.dart';
import '../models/street_investments.dart';
import '../models/saved_hand.dart';
import 'stack_manager_service.dart';
import 'pot_history_service.dart';

/// Synchronizes pot sizes and provides effective stack calculations.
class PotSyncService extends ChangeNotifier {
  PotSyncService({
    PotCalculator? potCalculator,
    StackManagerService? stackService,
    PotHistoryService? historyService,
    this.initialPot = 0,
  })  : _potCalculator = potCalculator ?? PotCalculator(),
        _stackService = stackService,
        _history = historyService ?? PotHistoryService();

  final PotCalculator _potCalculator;
  StackManagerService? _stackService;
  final PotHistoryService _history;

  /// Starting pot amount for the current hand.
  int initialPot;

  /// Provides access to recorded pot history.
  PotHistoryService get history => _history;

  /// Current pot size for each street.
  final List<int> pots = List.filled(4, 0);

  /// Calculated side pots for the current hand.
  final List<int> sidePots = [];

  /// Effective stack sizes recorded per street.
  Map<String, int> _effectiveStacks = {};

  set stackService(StackManagerService v) => _stackService = v;
  StackManagerService get stackService => _stackService!;

  /// Current effective stack sizes map.
  Map<String, int> get effectiveStacks =>
      Map<String, int>.from(_effectiveStacks);

  /// Computes pot sizes for [actions] without mutating [pots].
  List<int> computePots(List<ActionEntry> actions) {
    final investments = StreetInvestments();
    for (final a in actions) {
      investments.addAction(a);
    }
    return _potCalculator.calculatePots(actions, investments,
        initialPot: initialPot);
  }

  /// Calculates side pots based on current player investments.
  List<int> computeSidePots() {
    final contributions = <int>[];
    for (final i in stackService.stackSizes.keys) {
      contributions.add(stackService.getTotalInvested(i));
    }
    contributions.sort();
    final pots = <int>[];
    int prev = 0;
    int remaining = contributions.length;
    for (final c in contributions) {
      if (c > prev) {
        pots.add((c - prev) * remaining);
        prev = c;
      }
      remaining--;
    }
    return pots.length > 1 ? pots.sublist(1) : <int>[];
  }

  /// Recomputes and stores [sidePots].
  void updateSidePots() {
    sidePots
      ..clear()
      ..addAll(computeSidePots());
    notifyListeners();
  }

  /// Recompute [pots] based on visible [actions] and record history.
  void updatePots(List<ActionEntry> actions) {
    final p = computePots(actions);
    for (int i = 0; i < pots.length; i++) {
      pots[i] = p[i];
    }
    updateSidePots();
    _history.record(actions.length, pots);
    notifyListeners();
  }

  /// Updates [pots] using only actions up to [playbackIndex].
  void updateForPlayback(int playbackIndex, List<ActionEntry> actions) {
    final subset = actions.take(playbackIndex).toList();
    final p = computePots(subset);
    for (int i = 0; i < pots.length; i++) {
      pots[i] = p[i];
    }
    updateSidePots();
    _history.record(playbackIndex, pots);
    notifyListeners();
  }

  /// Returns the recorded pot sizes for [index].
  List<int> potsAt(int index) => _history.potsAt(index);

  /// Returns the pot size for [street] at [index].
  int potForStreet(int street, int index) =>
      _history.potForStreet(street, index);

  /// Discards history entries after [index].
  void rewindHistory(int index) => _history.rewindTo(index);

  /// Calculates the effective stack size using [actions] visible up to the
  /// current point in the hand.
  int calculateEffectiveStack(int currentStreet, List<ActionEntry> actions) {
    int? minStack;
    for (final entry in stackService.stackSizes.entries) {
      final index = entry.key;
      final folded = actions.any((a) =>
          a.playerIndex == index &&
          a.action == 'fold' &&
          a.street <= currentStreet);
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

  /// Recompute and store effective stacks for [actions].
  Map<String, int> updateEffectiveStacks(
      List<ActionEntry> actions, int numberOfPlayers) {
    _effectiveStacks =
        calculateEffectiveStacksPerStreet(actions, numberOfPlayers);
    notifyListeners();
    return effectiveStacks;
  }

  /// Serializes the effective stacks map.
  Map<String, int> toJson() => Map<String, int>.from(_effectiveStacks);

  /// Returns `null` if [_effectiveStacks] is empty, otherwise [toJson()].
  Map<String, int>? toNullableJson() =>
      _effectiveStacks.isEmpty ? null : toJson();

  /// Restores effective stacks from [json].
  void restoreFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      _effectiveStacks.clear();
      notifyListeners();
      return;
    }
    _effectiveStacks = {
      for (final entry in json.entries) entry.key: entry.value as int
    };
    notifyListeners();
  }

  /// Restores effective stacks from [hand], computing them when missing.
  void restoreFromHand(SavedHand hand) {
    if (hand.effectiveStacksPerStreet != null) {
      restoreFromJson(hand.effectiveStacksPerStreet);
    } else {
      updateEffectiveStacks(hand.actions, hand.numberOfPlayers);
    }
  }

  /// Reset all stored pot information and history.
  void reset() {
    for (int i = 0; i < pots.length; i++) {
      pots[i] = 0;
    }
    sidePots.clear();
    _effectiveStacks.clear();
    _history.clear();
    initialPot = 0;
    notifyListeners();
  }
}
