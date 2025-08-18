import '../models/action_entry.dart';
import '../models/street_investments.dart';

/// Utility for computing pot sizes for each street.
class PotCalculator {
  /// Returns the cumulative pot for each street based on [investments].
  List<int> calculatePots(
    List<ActionEntry> actions,
    StreetInvestments investments, {
    int initialPot = 0,
  }) {
    final List<int> pots = List<int>.filled(4, 0);
    int cumulative = initialPot;
    for (int s = 0; s < pots.length; s++) {
      cumulative += investments.getTotalInvestedOnStreet(s);
      pots[s] = cumulative;
    }
    return pots;
  }
}
