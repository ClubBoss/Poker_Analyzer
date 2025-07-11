import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/saved_hand.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../services/saved_hand_manager_service.dart';
import '../helpers/poker_position_helper.dart';

class TrainingPackService {
  const TrainingPackService._();

  static TrainingPackSpot _spotFromHand(SavedHand h) {
    final hero = h.playerCards[h.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final board = [for (final c in h.boardCards) '${c.rank}${c.suit}'];
    final actions = <int, List<ActionEntry>>{};
    for (final a in h.actions) {
      actions.putIfAbsent(a.street, () => []).add(ActionEntry(
        a.street,
        a.playerIndex,
        a.action,
        amount: a.amount,
        generated: a.generated,
        manualEvaluation: a.manualEvaluation,
        customLabel: a.customLabel,
      ));
    }
    final stacks = <String, double>{
      for (final e in h.stackSizes.entries) '${e.key}': e.value.toDouble()
    };
    final tags = List<String>.from(h.tags);
    final cat = h.category;
    if (cat != null && cat.isNotEmpty) tags.add('cat:$cat');
    return TrainingPackSpot(
      id: const Uuid().v4(),
      title: h.name,
      hand: HandData(
        heroCards: hero,
        position: parseHeroPosition(h.heroPosition),
        heroIndex: h.heroIndex,
        playerCount: h.numberOfPlayers,
        board: board,
        actions: actions,
        stacks: stacks,
        anteBb: h.anteBb,
      ),
      tags: tags,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromCategory(
      BuildContext context, String category) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final mistakes = [
      for (final h in hands)
        if (h.category == category &&
            h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase())
          h
    ];
    if (mistakes.isEmpty) return null;
    mistakes.sort((a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
    final selected = mistakes.take(10).toList();
    final spots = [for (final h in selected) _spotFromHand(h)];
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: category,
      spots: spots,
    );
  }

  static Future<TrainingPackTemplate?> createDrillFromTopCategories(
      BuildContext context) async {
    final hands = context.read<SavedHandManagerService>().hands;
    final byCat = <String, List<SavedHand>>{};
    final ev = <String, double>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      byCat.putIfAbsent(cat, () => []).add(h);
      ev[cat] = (ev[cat] ?? 0) + (h.evLoss ?? 0);
    }
    if (ev.length < 3) return null;
    final cats = ev.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final spots = <TrainingPackSpot>[];
    for (final e in cats.take(3)) {
      final list = byCat[e.key]!..sort(
          (a, b) => (b.evLoss ?? 0).compareTo(a.evLoss ?? 0));
      for (final h in list.take(5)) {
        spots.add(_spotFromHand(h));
      }
    }
    if (spots.isEmpty) return null;
    return TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Комбо Drill: топ ошибки',
      spots: spots,
    );
  }
}
