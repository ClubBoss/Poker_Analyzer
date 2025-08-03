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
    saveSpots();
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
    // Remove the spot from the filtered list and keep a reference to it.
    final item = _removeFromVisible(oldIndex);
    // Insert the spot into the filtered list at its new position.
    _insertIntoVisible(newIndex, item);
    // Remove the corresponding spot from the base list.
    final baseItem = _removeFromBase(item);
    // Determine the insertion index within the base list.
    final baseIndex = _findBaseInsertionIndex(newIndex);
    // Insert the spot into the base list at the computed position.
    _insertIntoBase(baseIndex, baseItem);
    saveSpots();
    notifyListeners();
  }

  /// Removes the spot from the currently filtered list.
  TrainingSpot _removeFromVisible(int index) => _spots.removeAt(index);

  /// Inserts the spot into the currently filtered list.
  void _insertIntoVisible(int index, TrainingSpot spot) =>
      _spots.insert(index, spot);

  /// Removes the spot from the full list of spots.
  TrainingSpot _removeFromBase(TrainingSpot spot) =>
      _allSpots.removeAt(_allSpots.indexOf(spot));

  /// Computes the index where the spot should be inserted in the base list.
  int _findBaseInsertionIndex(int newIndex) {
    final target = newIndex >= _spots.length ? null : _spots[newIndex];
    return target == null ? _allSpots.length : _allSpots.indexOf(target);
  }

  /// Inserts the spot into the full list of spots.
  void _insertIntoBase(int index, TrainingSpot spot) =>
      _allSpots.insert(index, spot);

  void clearFilters() {
    _stackFilter = null;
    _applyStackFilter();
    notifyListeners();
  }
}
