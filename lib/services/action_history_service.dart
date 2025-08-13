import '../models/action_entry.dart';

/// Centralized storage and management of action history grouped by street.
class ActionHistoryService {
  /// Streets that should appear expanded in history views.
  final Set<int> expandedStreets = {0, 1, 2, 3};

  /// Internal map of actions per street. Indexes correspond to street numbers.
  final Map<int, List<ActionEntry>> _actionsByStreet = {
    for (var i = 0; i < 4; i++) i: <ActionEntry>[]
  };

  /// Complete list of actions in their original order.
  List<ActionEntry> _allActions = [];

  /// Update history from [actions]. If [visibleCount] is provided only the first
  /// [visibleCount] actions are taken into account. Existing lists are replaced.
  void updateHistory(List<ActionEntry> actions, {int? visibleCount}) {
    _allActions = List<ActionEntry>.from(actions);
    for (final list in _actionsByStreet.values) {
      list.clear();
    }
    final source =
        visibleCount != null ? actions.take(visibleCount).toList() : actions;
    for (final a in source) {
      _actionsByStreet[a.street]?.add(a);
    }
  }

  /// Clears all stored actions.
  void clear() {
    for (final list in _actionsByStreet.values) {
      list.clear();
    }
    _allActions.clear();
  }

  /// Returns the list of actions for [street]. If [collapsed] is true and the
  /// list is longer than [limit], only the last [limit] actions are returned.
  List<ActionEntry> actionsForStreet(int street,
      {bool collapsed = false, int limit = 5}) {
    final list = _actionsByStreet[street] ?? const <ActionEntry>[];
    if (!collapsed || list.length <= limit) return List.unmodifiable(list);
    return List.unmodifiable(list.sublist(list.length - limit));
  }

  /// Returns grouped actions for HUD overlay respecting collapsed streets.
  Map<int, List<ActionEntry>> hudView({int limit = 5}) {
    return {
      for (int i = 0; i < 4; i++)
        i: actionsForStreet(i,
            collapsed: !expandedStreets.contains(i), limit: limit)
    };
  }

  /// Returns the index of [entry] in the full action list.
  int indexOf(ActionEntry entry) => _allActions.indexOf(entry);

  /// Removes the action at [index] from history and returns it.
  ActionEntry? removeAt(int index) {
    if (index < 0 || index >= _allActions.length) return null;
    final removed = _allActions.removeAt(index);
    _actionsByStreet[removed.street]?.remove(removed);
    return removed;
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
      [
        for (int i = 0; i < 4; i++)
          if (collapsed == null || !collapsed.contains(i)) i
      ],
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
    return [
      for (int i = 0; i < count; i++)
        if (!expandedStreets.contains(i)) i
    ];
  }

  /// Builds a short summary for the last action on [street].
  String streetSummary(int street, Map<int, String> positions) {
    final list = actionsForStreet(street);
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
