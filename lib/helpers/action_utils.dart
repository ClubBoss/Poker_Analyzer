// Helper utilities and extensions for working with ActionEntry lists.
import '../models/action_entry.dart';

/// Extension helpers on [ActionEntry] for hero/opponent checks.
extension ActionEntryX on ActionEntry {
  /// Returns true if this action was performed by the hero at [heroIndex].
  bool isHero(int heroIndex) => playerIndex == heroIndex;

  /// Returns true if this action was performed by an opponent of the hero.
  bool isOpponent(int heroIndex) => playerIndex != heroIndex;
}

/// Provides convenient list helpers for [ActionEntry].
extension ActionEntryListX on List<ActionEntry> {
  /// Filters actions to only those taken by opponents of the hero.
  List<ActionEntry> againstHero(int heroIndex) =>
      where((a) => a.isOpponent(heroIndex)).toList();
}

