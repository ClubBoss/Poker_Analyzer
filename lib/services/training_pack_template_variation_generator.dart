// Generates multiple TrainingPackTemplateV2 objects from a base template
// and a [TrainingPackTemplateSet] describing variation rules.
import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import 'training_pack_template_expander_service.dart';

class TrainingPackTemplateSetGenerator {
  final TrainingPackTemplateExpanderService _expander;

  TrainingPackTemplateSetGenerator({
    TrainingPackTemplateExpanderService? expander,
  }) : _expander = expander ?? TrainingPackTemplateExpanderService();

  /// Generates pack templates based on [base] and variation rules in [set].
  ///
  /// The generator expands [set] into concrete [TrainingPackSpot]s and then
  /// applies player type, suit and stack depth variations. Each resulting spot
  /// is wrapped into a copy of [base] producing a distinct
  /// [TrainingPackTemplateV2].
  List<TrainingPackTemplateV2> generate({
    required TrainingPackTemplateV2 base,
    required TrainingPackTemplateSet set,
  }) {
    final expandedSpots = _expander.expand(set);
    final templates = <TrainingPackTemplateV2>[];
    var counter = 0;
    for (final spot in expandedSpots) {
      final playerTypes = set.playerTypeVariations.isNotEmpty
          ? set.playerTypeVariations
          : <String?>[null];
      final stackMods =
          set.stackDepthMods.isNotEmpty ? set.stackDepthMods : <int>[0];
      final suitFlags = set.suitAlternation ? [false, true] : [false];

      for (final pt in playerTypes) {
        for (final mod in stackMods) {
          for (final suit in suitFlags) {
            final newSpot = TrainingPackSpot.fromJson(spot.toJson());
            if (pt != null) {
              newSpot.meta['playerType'] = pt;
            }
            if (mod != 0) {
              final current = newSpot.hand.stacks['0'] ?? base.bb.toDouble();
              newSpot.hand.stacks = {
                ...newSpot.hand.stacks,
                '0': current + mod,
              };
            }
            if (suit) {
              newSpot.hand.heroCards = _alternateSuits(newSpot.hand.heroCards);
            }

            templates.add(
              _cloneBase(
                base,
                idSuffix: counter++,
                spot: newSpot,
                stackMod: mod,
              ),
            );
          }
        }
      }
    }
    return templates;
  }

  TrainingPackTemplateV2 _cloneBase(
    TrainingPackTemplateV2 base, {
    required int idSuffix,
    required TrainingPackSpot spot,
    required int stackMod,
  }) {
    return TrainingPackTemplateV2(
      id: '${base.id}_$idSuffix',
      name: base.name,
      description: base.description,
      goal: base.goal,
      audience: base.audience,
      theme: base.theme,
      tags: List<String>.from(base.tags),
      category: base.category,
      trainingType: base.trainingType,
      spots: [spot],
      spotCount: 1,
      dynamicSpots: const [],
      created: base.created,
      gameType: base.gameType,
      bb: base.bb + stackMod,
      positions: List<String>.from(base.positions),
      meta: Map<String, dynamic>.from(base.meta),
      recommended: base.recommended,
      requiresTheoryCompleted: base.requiresTheoryCompleted,
      targetStreet: base.targetStreet,
      unlockRules: base.unlockRules,
      requiredAccuracy: base.requiredAccuracy,
      minHands: base.minHands,
      isGeneratedPack: true,
      isSampledPack: base.isSampledPack,
    );
  }

  String _alternateSuits(String cards) {
    final parts = cards.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return cards;
    final c1 = parts[0];
    var c2 = parts[1];
    if (c1.length < 2 || c2.length < 2) return cards;
    final s1 = c1.substring(1, 2);
    final s2 = c2.substring(1, 2);
    const suits = ['s', 'h', 'd', 'c'];
    if (s1 == s2) {
      // Make offsuit by picking any suit different from the first.
      final alt = suits.firstWhere((s) => s != s1, orElse: () => s1);
      c2 = c2[0] + alt;
    } else {
      // Make suited by copying the first suit.
      c2 = c2[0] + s1;
    }
    return '$c1 $c2';
  }
}
