import 'package:uuid/uuid.dart';

import '../models/training_pack_template_set.dart';
import '../models/inline_theory_entry.dart';
import '../models/spot_seed_format.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../models/constraint_set.dart';
import 'training_pack_template_expander_service.dart';
import 'auto_spot_theory_injector_service.dart';
import 'line_graph_engine.dart';

/// Orchestrates board-based and line-based expansions into concrete
/// [TrainingPackSpot]s.
///
/// [TrainingPackGeneratorEngineV2] converts a [TrainingPackTemplateSet]
/// into a list of fully formed spots by combining constraint-based
/// board expansions and action line patterns. Each generated spot inherits
/// metadata from the template's base spot and receives auto-generated tags.
class TrainingPackGeneratorEngineV2 {
  final TrainingPackTemplateExpanderService _expander;
  final AutoSpotTheoryInjectorService _injector;
  final LineGraphEngine _lineEngine;
  final Uuid _uuid;

  const TrainingPackGeneratorEngineV2({
    TrainingPackTemplateExpanderService? expander,
    AutoSpotTheoryInjectorService? injector,
    LineGraphEngine? lineEngine,
    Uuid? uuid,
  })
      : _expander = expander ?? TrainingPackTemplateExpanderService(),
        _injector = injector ?? AutoSpotTheoryInjectorService(),
        _lineEngine = lineEngine ?? LineGraphEngine(),
        _uuid = uuid ?? const Uuid();

  /// Generates all spots defined by [set].
  ///
  /// The method combines board-based expansions with line pattern results
  /// and returns a unified list of [TrainingPackSpot]s. Optional
  /// [theoryIndex] entries are forwarded to the expander for enrichment.
  List<TrainingPackSpot> generate(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) {
    final baseSpot = set.baseSpot;

    // Board-based expansions.
    final spots = _expander.expand(set);
    for (final s in spots) {
      s.tags = {...s.tags, ..._autoTags(s)}.toList()..sort();
    }

    // Line pattern expansions.
    final seeds = _expander.expandLines(set, theoryIndex: theoryIndex);
    for (var i = 0; i < seeds.length; i++) {
      final seed = seeds[i];
      final pattern = set.linePatterns[i];
      final lineTags = _lineEngine.build(pattern).tags;
      final copy = _cloneBase(baseSpot);

      copy.hand.position = parseHeroPosition(seed.position);
      final board = [for (final c in seed.board) '${c.rank}${c.suit}'];
      copy.hand.board = List<String>.from(board);
      copy.board = board;
      if (seed.villainActions.isNotEmpty) {
        copy.villainAction = seed.villainActions.last;
      }
      copy.street = _streetFromBoard(board.length);

      final tags = {...baseSpot.tags, ...lineTags, ..._autoTags(copy)};
      copy.tags = tags.toList()..sort();
      spots.add(copy);
    }

    // Postflop shorthand line expansions.
    if (set.postflopLines.isNotEmpty) {
      final lineSeeds = _expander.expandPostflopLines(set);
      for (final seed in lineSeeds) {
        final copy = _cloneBase(baseSpot);

        copy.hand.position = parseHeroPosition(seed.position);
        final board = [for (final c in seed.board) '${c.rank}${c.suit}'];
        copy.hand.board = List<String>.from(board);
        copy.board = board;
        copy.street = _streetFromBoard(board.length);
        copy.meta['previousActions'] = List<String>.from(seed.previousActions);

        final tags = {...baseSpot.tags, ...seed.tags, ..._autoTags(copy)};
        copy.tags = tags.toList()..sort();
        spots.add(copy);
      }
    }

    // Inject theory links based on final tag sets.
    _injector.injectAll(spots);
    return spots;
  }

  /// Generates spot lists for each output variant in [set].
  ///
  /// When no [TrainingPackTemplateSet.outputVariants] are defined this simply
  /// returns a single-element list containing [generate]'s result.
  List<List<TrainingPackSpot>> generateOutputs(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) {
    if (set.outputVariants.isEmpty) {
      return [generate(set, theoryIndex: theoryIndex)];
    }
    final results = <List<TrainingPackSpot>>[];
    for (final variant in set.outputVariants) {
      final merged = TrainingPackTemplateSet(
        baseSpot: set.baseSpot,
        variations: [
          for (final v in set.variations) _mergeConstraints(v, variant),
        ],
        playerTypeVariations: set.playerTypeVariations,
        suitAlternation: set.suitAlternation,
        stackDepthMods: set.stackDepthMods,
        linePatterns: set.linePatterns,
        postflopLines: set.postflopLines,
        boardTexturePreset: set.boardTexturePreset,
        excludeBoardTexturePresets: set.excludeBoardTexturePresets,
        requiredBoardClusters: set.requiredBoardClusters,
        excludedBoardClusters: set.excludedBoardClusters,
        expandAllLines: set.expandAllLines,
        postflopLineSeed: set.postflopLineSeed,
      );
      results.add(generate(merged, theoryIndex: theoryIndex));
    }
    return results;
  }

  ConstraintSet _mergeConstraints(ConstraintSet base, ConstraintSet variant) {
    return ConstraintSet(
      boardTags: base.boardTags,
      positions: base.positions,
      handGroup: base.handGroup,
      villainActions: base.villainActions,
      targetStreet: variant.targetStreet ?? base.targetStreet,
      requiredTags: {...base.requiredTags, ...variant.requiredTags}.toList(),
      excludedTags: {...base.excludedTags, ...variant.excludedTags}.toList(),
      position: base.position,
      opponentPosition: base.opponentPosition,
      boardTexture: base.boardTexture,
      minStack: base.minStack,
      maxStack: base.maxStack,
      boardConstraints: [...base.boardConstraints, ...variant.boardConstraints],
      linePattern: base.linePattern,
      overrides: base.overrides,
      tags: base.tags,
      tagMergeMode: base.tagMergeMode,
      metadata: base.metadata,
      metaMergeMode: base.metaMergeMode,
      theoryLink: base.theoryLink,
    );
  }

  TrainingPackSpot _cloneBase(TrainingPackSpot base) {
    final map = Map<String, dynamic>.from(base.toJson());
    map['id'] = _uuid.v4();
    final clone = TrainingPackSpot.fromJson(map);
    clone.templateSourceId = base.id;
    clone.tags = List<String>.from(base.tags);
    clone.meta = Map<String, dynamic>.from(base.meta);
    clone.theoryLink = base.theoryLink;
    return clone;
  }

  int _streetFromBoard(int len) {
    if (len >= 5) return 3;
    if (len == 4) return 2;
    if (len == 3) return 1;
    return 0;
  }

  List<String> _autoTags(TrainingPackSpot spot) {
    final set = <String>{};
    final pos = spot.hand.position;
    if (pos != HeroPosition.unknown) {
      set.add(pos.name.toUpperCase());
    }
    final players = spot.hand.playerCount;
    if (players <= 2) {
      set.add('HU');
    } else if (players == 3) {
      set.add('3way');
    } else {
      set.add('${players}way');
    }
    final stack = spot.hand.stacks['${spot.hand.heroIndex}'];
    if (stack != null) {
      set.add('${stack.round()}bb');
      if (stack <= 10) set.add('short');
      if (stack >= 40) set.add('deep');
    }
    final len = spot.board.length;
    if (len >= 3) set.add('flop');
    if (len >= 4) set.add('turn');
    if (len >= 5) set.add('river');
    final list = set.toList();
    list.sort();
    return list;
  }
}
