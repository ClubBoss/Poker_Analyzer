import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';

class SavedHandSessionStats {
  SavedHandSessionStats(this.start, this.end, this.count, this.correct,
      this.incorrect,
      {this.evAvg, this.icmAvg});

  final DateTime start;
  final DateTime end;
  final int count;
  final int correct;
  final int incorrect;
  final double? evAvg;
  final double? icmAvg;

  Duration get duration => end.difference(start);
  double? get winrate {
    final total = correct + incorrect;
    return total > 0 ? correct / total * 100 : null;
  }
}

class SavedHandStatsService extends ChangeNotifier {
  SavedHandStatsService({required SavedHandManagerService manager})
      : _manager = manager {
    _manager.addListener(notifyListeners);
  }

  final SavedHandManagerService _manager;

  List<SavedHand> get hands => _manager.hands;

  Map<int, List<SavedHand>> handsBySession() {
    final Map<int, List<SavedHand>> grouped = {};
    for (final hand in hands) {
      grouped.putIfAbsent(hand.sessionId, () => []).add(hand);
    }
    return grouped;
  }

  SavedHandSessionStats sessionStats(List<SavedHand> hands) {
    final list = List<SavedHand>.from(hands)
      ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    final start = list.first.savedAt;
    final end = list.last.savedAt;
    int correct = 0;
    int incorrect = 0;
    double evSum = 0;
    double icmSum = 0;
    int evCount = 0;
    int icmCount = 0;
    for (final h in list) {
      final expected = h.expectedAction;
      final gto = h.gtoAction;
      if (expected != null && gto != null) {
        if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
          correct++;
        } else {
          incorrect++;
        }
      }
      final ev = h.heroEv;
      if (ev != null) {
        evSum += ev;
        evCount++;
      }
      final icm = h.heroIcmEv;
      if (icm != null) {
        icmSum += icm;
        icmCount++;
      }
    }
    final evAvg = evCount > 0 ? evSum / evCount : null;
    final icmAvg = icmCount > 0 ? icmSum / icmCount : null;
    return SavedHandSessionStats(start, end, list.length, correct, incorrect,
        evAvg: evAvg, icmAvg: icmAvg);
  }

  List<SavedHand> filtered({String? tag, String? position, DateTimeRange? range}) {
    return [
      for (final h in hands)
        if ((tag == null || h.tags.contains(tag)) &&
            (position == null || h.heroPosition == position) &&
            (range == null ||
                (!h.date.isBefore(range.start) && !h.date.isAfter(range.end))))
          h
    ];
  }

  List<SavedHand> byTag(String tag) => filtered(tag: tag);

  List<SavedHand> byPosition(String position) => filtered(position: position);

  List<SavedHand> byDateRange(DateTimeRange range) => filtered(range: range);

  List<SavedHand> currentErrorFreeStreak() {
    final result = <SavedHand>[];
    for (int i = hands.length - 1; i >= 0; i--) {
      final h = hands[i];
      final expected = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (expected == null || gto == null || expected != gto) {
        break;
      }
      result.insert(0, h);
    }
    return result;
  }

  List<List<SavedHand>> completedErrorFreeStreaks() {
    final List<List<SavedHand>> streaks = [];
    final List<SavedHand> current = [];

    bool isCorrect(SavedHand h) {
      final expected = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      return expected != null && gto != null && expected == gto;
    }

    for (final h in hands) {
      if (isCorrect(h)) {
        current.add(h);
      } else {
        if (current.length >= 5) {
          streaks.add(List<SavedHand>.from(current));
        }
        current.clear();
      }
    }

    return streaks.reversed.toList();
  }

  List<SavedHand> filterByCategory(String category) {
    final result = [
      for (final h in hands)
        if (h.category == category &&
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h
    ];
    result.sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    return result;
  }

  bool hasSimilarMistakes(SavedHand hand) {
    final cat = hand.category;
    final pos = hand.heroPosition;
    final stack = hand.stackSizes[hand.heroIndex];
    if (cat == null || stack == null) return false;
    return hands.any(
      (h) =>
          h != hand &&
          h.category == cat &&
          h.heroPosition == pos &&
          h.stackSizes[h.heroIndex] == stack &&
          h.expectedAction != null &&
          h.gtoAction != null &&
          h.expectedAction!.trim().toLowerCase() !=
              h.gtoAction!.trim().toLowerCase(),
    );
  }

  List<MapEntry<String, double>> getTopMistakeCategories({int limit = 3}) {
    final map = <String, double>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      map[cat] = (map[cat] ?? 0) + (h.evLoss ?? 0);
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }
}

