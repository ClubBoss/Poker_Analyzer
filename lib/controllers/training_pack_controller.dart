import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../models/training_spot.dart';
import '../services/training_spot_storage_service.dart';

class TrainingPackController extends ChangeNotifier {
  final TrainingPack pack;
  final TrainingSpotStorageService storage;
  List<SavedHand> allHands;

  String? _stackFilter;
  List<TrainingSpot> _allSpots = const [];
  List<TrainingSpot> _spots = const [];
  List<SavedHand> _sessionHands = const [];

  TrainingPackController({
    required this.pack,
    required this.allHands,
    required this.storage,
  }) {
    _allSpots = List<TrainingSpot>.unmodifiable(pack.spots);
    _spots = _allSpots;
    _sessionHands = List<SavedHand>.unmodifiable(allHands);
  }

  UnmodifiableListView<TrainingSpot> get spots => UnmodifiableListView(_spots);
  UnmodifiableListView<SavedHand> get sessionHands =>
      UnmodifiableListView(_sessionHands);

  String? get stackFilter => _stackFilter;

  Future<void> loadSpots() async {
    final loaded = await storage.load();
    if (loaded.isNotEmpty) {
      _allSpots = List<TrainingSpot>.unmodifiable(loaded);
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

  bool _matchStack(int stack) {
    final r = _stackFilter;
    if (r == null) return true;
    if (r.endsWith('+')) {
      final min = int.tryParse(r.substring(0, r.length - 1)) ?? 0;
      return stack >= min;
    }
    final parts = r.split('-');
    if (parts.length == 2) {
      final min = int.tryParse(parts[0]) ?? 0;
      final max = int.tryParse(parts[1]) ?? 0;
      return stack >= min && stack <= max;
    }
    return true;
  }

  void _applyStackFilter() {
    _sessionHands = List<SavedHand>.unmodifiable([
      for (final h in allHands)
        if (_matchStack(h.stackSizes[h.heroIndex] ?? 0)) h,
    ]);
    _spots = List<TrainingSpot>.unmodifiable([
      for (final s in _allSpots)
        if (_matchStack(s.stacks[s.heroIndex])) s,
    ]);
  }

  void updateHands(List<SavedHand> hands) {
    allHands = hands;
    _applyStackFilter();
    notifyListeners();
  }

  void updateSpot(int index, TrainingSpot updated) {
    final baseIndex = _allSpots.indexOf(_spots[index]);
    if (baseIndex != -1) {
      final mutable = _allSpots.toList();
      mutable[baseIndex] = updated;
      _allSpots = List<TrainingSpot>.unmodifiable(mutable);
      _applyStackFilter();
      saveSpots();
      notifyListeners();
    }
  }

  void removeSpot(int index) {
    final spot = _spots[index];
    final mutable = _allSpots.toList()..remove(spot);
    _allSpots = List<TrainingSpot>.unmodifiable(mutable);
    saveSpots();
    _applyStackFilter();
    notifyListeners();
  }

  void setSpots(List<TrainingSpot> spots) {
    _allSpots = List<TrainingSpot>.unmodifiable(spots);
    _applyStackFilter();
    saveSpots();
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    final filtered = _spots.toList();
    final item = filtered.removeAt(oldIndex);
    filtered.insert(newIndex, item);

    final base = _allSpots.toList();
    final baseItem = base.removeAt(base.indexOf(item));
    final target = newIndex >= filtered.length ? null : filtered[newIndex];
    final baseIndex = target == null ? base.length : base.indexOf(target);
    base.insert(baseIndex, baseItem);

    _spots = List<TrainingSpot>.unmodifiable(filtered);
    _allSpots = List<TrainingSpot>.unmodifiable(base);
    saveSpots();
    notifyListeners();
  }

  void clearFilters() {
    _stackFilter = null;
    _applyStackFilter();
    notifyListeners();
  }
}

