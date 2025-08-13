import 'package:flutter/foundation.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';

/// Suggests thematic tags for booster packs.
class BoosterThematicTagger {
  const BoosterThematicTagger();

  /// Returns thematic tags for [pack] sorted by frequency.
  /// The method also logs tag frequencies to the console.
  List<String> suggestThematicTags(TrainingPackTemplateV2 pack) {
    final counts = <String, int>{};

    void addTag(String tag) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }

    for (final spot in pack.spots) {
      final heroPos = spot.hand.position;
      final heroOpts = [for (final o in spot.heroOptions) o.toLowerCase()];
      final villainAct = spot.villainAction?.toLowerCase() ?? '';
      final board = spot.board.isNotEmpty ? spot.board : spot.hand.board;

      if (heroPos == HeroPosition.utg && heroOpts.contains('open')) {
        addTag('UTG Open');
      }

      if (pack.positions.contains('sb') && pack.positions.contains('bb')) {
        addTag('SB vs BB');
      }

      if (villainAct.contains('limp') || heroOpts.contains('limp')) {
        addTag('Limped Pot');
      }

      if (villainAct.contains('3bet') ||
          villainAct.contains('3-bet') ||
          heroOpts.any((o) => o.contains('3bet'))) {
        addTag('3bet Spot');
      }

      if (spot.hand.playerCount > 2) addTag('Multiway Spot');

      if (board.isNotEmpty) addTag('Postflop Spot');
    }

    final isIcm = pack.tags.any((t) => t.toLowerCase().contains('icm')) ||
        pack.name.toLowerCase().contains('icm') ||
        pack.description.toLowerCase().contains('icm');
    final players = {for (final s in pack.spots) s.hand.playerCount};
    if (isIcm &&
        players.isNotEmpty &&
        players.reduce((a, b) => a < b ? a : b) <= 3) {
      addTag('ICM Final 3');
    }

    if (pack.gameType.name == 'live' ||
        pack.name.toLowerCase().contains('live')) {
      addTag('Live MTT');
    }

    if (pack.gameType.name == 'cash') {
      var stack = pack.bb;
      if (stack <= 0 && pack.spots.isNotEmpty) {
        final val = pack.spots.first.hand.stacks['0'];
        if (val != null) stack = val.toInt();
      }
      if (stack >= 90) addTag('Cash 100bb');
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final e in entries) {
      debugPrint('Thematic tag ${e.key}: ${e.value}');
    }

    return [for (final e in entries) e.key];
  }
}
