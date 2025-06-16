import '../models/action_entry.dart';

/// Provides grouped access to action history and manages expanded/collapsed
/// state for each street.
class ActionHistoryService {
  /// Streets that should appear expanded in history views.
  final Set<int> expandedStreets = {0, 1, 2, 3};

  /// Returns actions grouped by street. If [visibleCount] is provided, only
  /// the first [visibleCount] actions are considered.
  Map<int, List<ActionEntry>> groupByStreet(List<ActionEntry> actions,
      {int? visibleCount}) {
    final grouped = {for (var i = 0; i < 4; i++) i: <ActionEntry>[]};
    final list =
        visibleCount != null ? actions.take(visibleCount).toList() : actions;
    for (final a in list) {
      grouped[a.street]?.add(a);
    }
    return grouped;
  }

  /// Returns the list of actions for [street].
  List<ActionEntry> actionsForStreet(
      int street, List<ActionEntry> actions, {int? visibleCount}) {
    final grouped = groupByStreet(actions, visibleCount: visibleCount);
    return grouped[street] ?? const <ActionEntry>[];
  }

  /// Toggles expansion state for [street].
  void toggleStreet(int street) {
    if (expandedStreets.contains(street)) {
      expandedStreets.remove(street);
    } else {
      expandedStreets.add(street);
    }
  }

  /// Remove [street] from expanded list.
  void removeStreet(int street) => expandedStreets.remove(street);

  /// Add [street] to expanded list.
  void addStreet(int street) => expandedStreets.add(street);

  /// Replace the entire set of expanded streets.
  void setExpandedStreets(Iterable<int> streets) {
    expandedStreets
      ..clear()
      ..addAll(streets);
  }

  /// Restores expanded streets based on [collapsed] list from a saved hand.
  void restoreFromCollapsed(List<int>? collapsed) {
    setExpandedStreets(
      [for (int i = 0; i < 4; i++) if (collapsed == null || !collapsed.contains(i)) i],
    );
  }

  /// Collapses streets that have no actions.
  void autoCollapseStreets(List<ActionEntry> actions) {
    final active = actions.map((a) => a.street).toSet();
    for (int i = 0; i < 4; i++) {
      if (!active.contains(i)) {
        expandedStreets.remove(i);
      }
    }
  }

  /// Returns list of collapsed street indices.
  List<int> collapsedStreets({int count = 4}) {
    return [for (int i = 0; i < count; i++) if (!expandedStreets.contains(i)) i];
  }

  /// Builds a short summary for the last action on [street].
  String streetSummary(
      int street, List<ActionEntry> actions, Map<int, String> positions) {
    final list = actionsForStreet(street, actions);
    if (list.isEmpty) return 'Нет действий';
    final last = list.last;
    final pos = positions[last.playerIndex] ?? 'P${last.playerIndex + 1}';
    final action = last.action.isNotEmpty
        ? '${last.action[0].toUpperCase()}${last.action.substring(1)}'
        : last.action;
    final amount = last.amount != null ? ' ${last.amount}' : '';
    return '$pos $action$amount';
  }
}
