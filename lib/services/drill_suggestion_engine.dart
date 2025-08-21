import 'package:flutter/material.dart';

import '../helpers/poker_street_helper.dart';
import '../models/drill.dart';
import '../models/training_pack.dart';
import '../models/game_type.dart';
import '../models/saved_hand.dart';
import 'saved_hand_manager_service.dart';
import 'training_pack_storage_service.dart';

class DrillSuggestionEngine extends ChangeNotifier {
  final SavedHandManagerService _hands;
  final TrainingPackStorageService _packs;
  List<Drill> _drills = [];
  List<Drill> get suggestedDrills => List.unmodifiable(_drills);

  DrillSuggestionEngine({
    required SavedHandManagerService hands,
    required TrainingPackStorageService packs,
  })  : _hands = hands,
        _packs = packs {
    _update();
    _hands.addListener(_update);
  }

  void _update() {
    final map = <String, Map<String, int>>{};
    for (final h in _hands.hands) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null && exp != gto) {
        map.putIfAbsent(h.heroPosition, () => {});
        final street = streetName(h.boardStreet);
        map[h.heroPosition]![street] = (map[h.heroPosition]![street] ?? 0) + 1;
      }
    }
    final list = <Drill>[];
    for (final e in map.entries) {
      for (final s in e.value.entries) {
        list.add(Drill(position: e.key, street: s.key, count: s.value));
      }
    }
    list.sort((a, b) => b.count.compareTo(a.count));
    _drills = list.take(3).toList();
    notifyListeners();
  }

  TrainingPack startDrill(Drill d) {
    final hands = <SavedHand>[];
    for (final p in _packs.packs) {
      for (final h in p.hands) {
        if (h.heroPosition == d.position &&
            streetName(h.boardStreet) == d.street) {
          hands.add(h);
        }
      }
    }
    return TrainingPack(
      name: '${d.position} ${d.street}',
      description: 'Drill',
      gameType: GameType.cash,
      tags: const [],
      hands: hands,
      spots: const [],
      difficulty: 1,
    );
  }
}
