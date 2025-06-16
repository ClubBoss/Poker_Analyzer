import 'dart:collection';

/// Stores historical pot sizes for each playback index.
class PotHistoryService {
  final Map<int, List<int>> _history = SplayTreeMap();

  /// Record [pots] for the given playback [index].
  void record(int index, List<int> pots) {
    _history[index] = List<int>.from(pots);
  }

  /// Returns the pot sizes for [index] or zeros if none recorded.
  List<int> potsAt(int index) {
    final entry = _history[index];
    return entry != null ? List<int>.from(entry) : List<int>.filled(4, 0);
  }

  /// Returns the pot size for [street] at [index].
  int potForStreet(int street, int index) {
    final entry = _history[index];
    if (entry != null && street >= 0 && street < entry.length) {
      return entry[street];
    }
    return 0;
  }

  /// Remove all recorded history after [index]. Useful when rewinding edits.
  void rewindTo(int index) {
    final keys = _history.keys.where((k) => k > index).toList();
    for (final k in keys) {
      _history.remove(k);
    }
  }

  /// Clears all recorded pot history.
  void clear() => _history.clear();
}
