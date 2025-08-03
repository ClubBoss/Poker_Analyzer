import 'package:flutter/foundation.dart';

import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../models/training_spot.dart';
import '../services/training_spot_storage_service.dart';
import '../utils/stack_range_filter.dart';

class TrainingPackController extends ChangeNotifier {
  final TrainingPack pack;
  final TrainingSpotStorageService storage;
  List<SavedHand> allHands;

  String? _stackFilter;
  late List<TrainingSpot> _allSpots;
  late List<TrainingSpot> _spots;
  late List<SavedHand> _sessionHands;

  TrainingPackController({
    required this.pack,
    required this.allHands,
    required this.storage,
  }) {
    _allSpots = List.from(pack.spots);
    _spots = List.from(_allSpots);
    _sessionHands = List.from(allHands);
  }

  List<TrainingSpot> get spots => List.unmodifiable(_spots);
  List<SavedHand> get sessionHands => List.unmodifiable(_sessionHands);

  String? get stackFilter => _stackFilter;

  Future<void> loadSpots() async {
    final loaded = await storage.load();
    if (loaded.isNotEmpty) {
      _allSpots = loaded;
      _applyStackFilter();
      notifyListeners();
    }
  }

  Future<void> saveSpots() async {
    await storage.save(_allSpots);
  }

  void setStackFilter(String? value) {
    _stackFilter = value;
    _applyStackFilter();
    notifyListeners();
  }

  List<T> _filterByStack<T>(Iterable<T> items, bool Function(T item) predicate) {
    return [for (final item in items) if (predicate(item)) item];
  }

  void _applyStackFilter() {
    final filter = StackRangeFilter(_stackFilter);
    _sessionHands = _filterByStack(
      allHands,
      (h) => filter.matches(h.stackSizes[h.heroIndex] ?? 0),
    );
    _spots = _filterByStack(
      _allSpots,
      (s) => filter.matches(s.stacks[s.heroIndex]),
    );
  }

  void _commit() {
    _applyStackFilter();
    unawaited(saveSpots());
    notifyListeners();
  }

  void updateHands(List<SavedHand> hands) {
    allHands = hands;
    _applyStackFilter();
    notifyListeners();
  }

  void updateSpot(int index, TrainingSpot updated) {
    final baseIndex = _allSpots.indexOf(_spots[index]);
    if (baseIndex != -1) {
      _allSpots[baseIndex] = updated;
      _commit();
    }
  }

  void removeSpot(int index) {
    final spot = _spots.removeAt(index);
    _allSpots.remove(spot);
    _commit();
  }

  void setSpots(List<TrainingSpot> spots) {
    _allSpots = List.from(spots);
    _commit();
  }

  void reorder(int oldIndex, int newIndex) {
    _moveSpot(oldIndex, newIndex);
    _commit();
  }

  /// Moves a spot within the filtered list and keeps the base list in sync.
  ///
  /// [oldIndex] and [newIndex] refer to positions in the filtered list. This
  /// method removes the spot from both the filtered and base lists and
  /// reinserts it at the desired location using built-in list operations.
  void _moveSpot(int oldIndex, int newIndex) {
    // Remove the spot from the filtered list and from the full list.
    final spot = _spots.removeAt(oldIndex);
    _allSpots.remove(spot);

    // Determine the position in the base list based on the new filtered index.
    final baseIndex = newIndex >= _spots.length
        ? _allSpots.length
        : _allSpots.indexOf(_spots[newIndex]);

    // Insert the spot into both lists at their respective positions.
    _spots.insert(newIndex, spot);
    _allSpots.insert(baseIndex, spot);
  }

  void clearFilters() {
    _stackFilter = null;
    _applyStackFilter();
    notifyListeners();
  }
}
