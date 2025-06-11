import "action_entry.dart";

class StreetInvestments {
  final Map<int, Map<int, int>> _investments = {};
  int _currentStreet = 0;

  /// Adds an action's investment to the totals if applicable.
  void addAction(ActionEntry entry) {
    if (entry.action == 'call' ||
        entry.action == 'bet' ||
        entry.action == 'raise') {
      final streetMap = _investments.putIfAbsent(entry.street, () => {});
      streetMap[entry.playerIndex] =
          (streetMap[entry.playerIndex] ?? 0) + (entry.amount ?? 0);
    }
  }

  /// Clears data for [street] and sets it as the current street.
  void resetForNewStreet(int street) {
    _currentStreet = street;
    _investments[street] = {};
  }

  /// Returns the invested chips for [playerIndex] on [street] or
  /// the current street if [street] is omitted.
  int getInvestment(int playerIndex, [int? street]) {
    final s = street ?? _currentStreet;
    return _investments[s]?[playerIndex] ?? 0;
  }

  /// Returns total chips invested by [playerIndex] across all streets.
  int getTotalInvestment(int playerIndex) {
    int total = 0;
    for (final streetMap in _investments.values) {
      total += streetMap[playerIndex] ?? 0;
    }
    return total;
  }

  /// Returns total chips invested by all players on [street].
  int getTotalInvestedOnStreet(int street) {
    return _investments[street]?.values.fold<int>(0, (sum, v) => sum + v) ?? 0;
  }

  /// Utility to clear all stored investments.
  void clear() => _investments.clear();

  Map<int, Map<int, int>> get data => _investments;
}
