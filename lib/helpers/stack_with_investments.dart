/// Helper for tracking a player's stack along with investments per street.
class StackWithInvestments {
  /// The starting stack size.
  final int initialStack;

  final Map<int, int> _investments = {};

  StackWithInvestments(this.initialStack);

  /// Remaining stack after subtracting all investments.
  int get remainingStack =>
      initialStack - _investments.values.fold(0, (a, b) => a + b);

  /// Returns the invested chips for [street].
  int getInvestmentForStreet(int street) => _investments[street] ?? 0;

  /// Adds [amount] chips to the investment on [street].
  void addInvestment(int street, int amount) {
    if (amount == 0) return;
    _investments[street] = (_investments[street] ?? 0) + amount;
  }

  /// Clears all investments.
  void clear() => _investments.clear();
}
