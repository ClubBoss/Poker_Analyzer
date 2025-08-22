import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/game_type.dart';

/// Generates tags for YAML packs based on simple heuristics.
class YamlPackAutoTagEngine {
  YamlPackAutoTagEngine();

  /// Returns a sorted list of unique tags inferred from [pack]. Existing
  /// tags in the pack are preserved.
  List<String> autoTag(TrainingPackTemplateV2 pack) {
    final tags = <String>{...pack.tags};

    _detectPushFold(pack, tags);
    _detectIcm(pack, tags);
    _detectGameType(pack, tags);
    _detectHeroPosition(pack, tags);
    _detect3Bet(pack, tags);

    final list = tags.toList()..sort();
    return list;
  }

  void _detectPushFold(TrainingPackTemplateV2 pack, Set<String> tags) {
    if (pack.spots.isEmpty) return;
    var shortCount = 0;
    for (final s in pack.spots) {
      final heroStack = s.hand.stacks['${s.hand.heroIndex}'];
      if (heroStack != null && heroStack <= 15) shortCount++;
    }
    if (shortCount >= (pack.spots.length / 2)) {
      tags.add('pushfold');
    }
  }

  void _detectIcm(TrainingPackTemplateV2 pack, Set<String> tags) {
    if (pack.meta['icm'] == true) tags.add('icm');
  }

  void _detectGameType(TrainingPackTemplateV2 pack, Set<String> tags) {
    if (pack.gameType == GameType.cash) tags.add('cash');
  }

  void _detectHeroPosition(TrainingPackTemplateV2 pack, Set<String> tags) {
    final counts = <HeroPosition, int>{};
    for (final p in pack.positions) {
      final pos = parseHeroPosition(p);
      counts[pos] = (counts[pos] ?? 0) + 1;
    }
    for (final s in pack.spots) {
      final pos = s.hand.position;
      counts[pos] = (counts[pos] ?? 0) + 1;
    }
    var total = 0;
    counts.forEach((_, v) => total += v);
    if (total == 0) return;
    final maxEntry = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    if (maxEntry.value >= total / 2 && maxEntry.key != HeroPosition.unknown) {
      final label = maxEntry.key.name.toUpperCase();
      tags.add('hero$label');
    }
  }

  void _detect3Bet(TrainingPackTemplateV2 pack, Set<String> tags) {
    bool found = false;
    for (final s in pack.spots) {
      if (_spotContains3Bet(s)) {
        found = true;
        break;
      }
    }
    if (found) tags.add('3bet');
  }

  bool _spotContains3Bet(TrainingPackSpot s) {
    for (final o in s.heroOptions) {
      if (o.toLowerCase().contains('3bet')) return true;
    }
    final villain = s.villainAction?.toLowerCase();
    if (villain != null && villain.contains('3bet')) return true;
    for (final list in s.hand.actions.values) {
      for (final a in list) {
        if (a.action.toLowerCase().contains('3bet')) return true;
      }
    }
    return false;
  }
}
