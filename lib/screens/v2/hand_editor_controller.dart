import 'package:flutter/material.dart';

import '../../models/v2/hero_position.dart';
import '../../models/v2/training_pack_spot.dart';

/// Maintains the mutable state for [HandEditorScreen].
class HandEditorController extends ChangeNotifier {
  final TrainingPackSpot spot;
  final TextEditingController cardsCtr;
  final List<TextEditingController> stackCtr;
  HeroPosition position;
  int street = 0;

  HandEditorController(this.spot)
      : cardsCtr = TextEditingController(text: spot.hand.heroCards),
        position = spot.hand.position,
        stackCtr = [
          for (var i = 0; i < spot.hand.playerCount; i++)
            TextEditingController(
                text: spot.hand.stacks['$i']?.toString() ?? ''),
        ];

  void update() {
    updateStacks();
    spot.hand.heroCards = cardsCtr.text;
    spot.hand.position = position;
    notifyListeners();
  }

  void updateStacks() {
    final m = <String, double>{};
    for (var i = 0; i < stackCtr.length; i++) {
      final v = double.tryParse(stackCtr[i].text) ?? 0;
      m['$i'] = v;
    }
    spot.hand.stacks = m;
  }

  bool validateStacks() {
    final stacks = spot.hand.stacks;
    final hero = stacks['${spot.hand.heroIndex}'];
    if (hero == null || hero <= 0) return false;
    int count = 0;
    for (final v in stacks.values) {
      if (v > 0) count++;
    }
    return count >= 2;
  }

  void setPlayerCount(int v) {
    for (var i = stackCtr.length; i < v; i++) {
      stackCtr.add(
        TextEditingController(text: spot.hand.stacks['$i']?.toString() ?? ''),
      );
    }
    while (stackCtr.length > v) {
      stackCtr.removeLast().dispose();
    }
    spot.hand.playerCount = v;
    if (spot.hand.heroIndex >= v) {
      spot.hand.heroIndex = 0;
    }
    updateStacks();
    notifyListeners();
  }

  void setHeroIndex(int v) {
    spot.hand.heroIndex = v;
    notifyListeners();
  }

  void setStreet(int v) {
    street = v;
    notifyListeners();
  }

  String? validate() {
    final count = spot.hand.playerCount;
    if (count < 2 || count > 9) {
      return 'Ошибка: количество игроков 2-9';
    }
    if (spot.hand.heroIndex >= count) {
      return 'Ошибка: hero index выходит за пределы';
    }
    if (!validateStacks()) {
      return 'Ошибка: стеков недостаточно для розыгрыша';
    }
    return null;
  }

  @override
  void dispose() {
    cardsCtr.dispose();
    for (final c in stackCtr) {
      c.dispose();
    }
    super.dispose();
  }
}
