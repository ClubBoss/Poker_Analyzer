import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/constraint_set.dart';
import '../models/spot_seed_format.dart';
import '../models/spot_seed.dart';
import '../models/card_model.dart';
import '../models/inline_theory_entry.dart';
import '../models/postflop_line.dart';
import 'constraint_resolver_engine_v2.dart';
import 'auto_spot_theory_injector_service.dart';
import 'full_board_generator_v2.dart';
import 'line_graph_engine.dart';
import 'inline_theory_node_linker.dart';
import 'board_texture_preset_library.dart';
import 'board_cluster_constraint_engine.dart';
import 'dart:math';

/// Expands a [TrainingPackTemplateSet] into concrete [TrainingPackSpot]s using
/// [ConstraintResolverEngine].
///
/// Each entry in [TrainingPackTemplateSet.variations] is treated as a
/// [ConstraintSet] describing property overrides and tag/metadata updates. The
/// resolver generates the cartesian product of all values within a variation and
/// applies them to the base spot, producing a unique spot for every combination.
class TrainingPackTemplateExpanderService {
  final ConstraintResolverEngine _engine;
  final AutoSpotTheoryInjectorService _injector;
  final FullBoardGeneratorV2 _boardGenerator;
  final LineGraphEngine _lineEngine;
  final InlineTheoryNodeLinker _theoryLinker;

  TrainingPackTemplateExpanderService({
    ConstraintResolverEngine? engine,
    AutoSpotTheoryInjectorService? injector,
    FullBoardGeneratorV2? boardGenerator,
    LineGraphEngine? lineEngine,
    InlineTheoryNodeLinker? theoryLinker,
  })  : _engine = engine ?? const ConstraintResolverEngine(),
        _injector = injector ?? AutoSpotTheoryInjectorService(),
        _boardGenerator = boardGenerator ?? const FullBoardGeneratorV2(),
        _lineEngine = lineEngine ?? LineGraphEngine(),
        _theoryLinker = theoryLinker ?? const InlineTheoryNodeLinker();

  bool _isManual(TrainingPackTemplateSet set) =>
      set.baseSpot.meta['manualSource'] == true;

  /// Generates all spots described by [set] and injects theory links.
  List<TrainingPackSpot> expand(TrainingPackTemplateSet set, {Random? rng}) {
    if (_isManual(set)) return [];
    final processed = [
      for (final v in set.variations)
        _expandBoards(
          v,
          requiredBoardClusters: set.requiredBoardClusters,
          excludedBoardClusters: set.excludedBoardClusters,
        ),
    ];
    final spots = _engine.apply(set.baseSpot, processed, rng: rng);
    if (set.requiredBoardClusters.isNotEmpty ||
        set.excludedBoardClusters.isNotEmpty) {
      spots.retainWhere((s) {
        final cards = [
          for (final c in s.board)
            CardModel(rank: c[0], suit: c.length > 1 ? c[1] : ''),
        ];
        return BoardClusterConstraintEngine.matches(
          board: cards,
          requiredClusters: set.requiredBoardClusters,
          excludedClusters: set.excludedBoardClusters,
        );
      });
    }
    _injector.injectAll(spots);
    return spots;
  }

  // Deprecated multi-output expansion method removed in favor of handling
  // variants at the auto-generation layer.

  ConstraintSet _expandBoards(
    ConstraintSet set, {
    List<String> requiredBoardClusters = const [],
    List<String> excludedBoardClusters = const [],
  }) {
    if (set.boardConstraints.isEmpty &&
        !set.overrides.containsKey('boardConstraints')) {
      return set;
    }

    final overrides = Map<String, List<dynamic>>.from(set.overrides);
    final constraints = <Map<String, dynamic>>[];

    if (set.boardConstraints.isNotEmpty) {
      constraints.addAll(set.boardConstraints);
    }
    if (overrides.containsKey('boardConstraints')) {
      for (final c in overrides.remove('boardConstraints')!) {
        if (c is Map<String, dynamic>) {
          constraints.add(Map<String, dynamic>.from(c));
        }
      }
    }

    final boards = <List<String>>[];
    String? streetOverride = set.targetStreet;
    for (final params in constraints) {
      var map = Map<String, dynamic>.from(params);
      final preset = map.remove('preset');
      if (preset != null) {
        final expanded = BoardTexturePresetLibrary.get(preset.toString());
        map = {...expanded, ...map};
      }
      final street = map.remove('targetStreet')?.toString().toLowerCase();
      if (street != null) streetOverride = street;
      final paramRequired = <String>[
        for (final c in (map.remove('requiredBoardClusters') as List? ?? []))
          c.toString(),
      ];
      final paramExcluded = <String>[
        for (final c in (map.remove('excludedBoardClusters') as List? ?? []))
          c.toString(),
      ];
      final generated = _boardGenerator.generate(
        map,
        requiredBoardClusters: [...requiredBoardClusters, ...paramRequired],
        excludedBoardClusters: [...excludedBoardClusters, ...paramExcluded],
      );
      if (street == 'turn') {
        final seen = <String>{};
        for (final b in generated) {
          final combo = [...b.flop, b.turn];
          final key = combo.join(',');
          if (seen.add(key)) boards.add(combo);
        }
      } else {
        for (final b in generated) {
          boards.add([...b.flop, b.turn, b.river]);
        }
      }
    }

    overrides['board'] = boards;
    return ConstraintSet(
      boardTags: set.boardTags,
      positions: set.positions,
      handGroup: set.handGroup,
      villainActions: set.villainActions,
      targetStreet: streetOverride,
      overrides: overrides,
      tags: set.tags,
      tagMergeMode: set.tagMergeMode,
      metadata: set.metadata,
      metaMergeMode: set.metaMergeMode,
      theoryLink: set.theoryLink,
      linePattern: set.linePattern,
    );
  }

  /// Generates [SpotSeedFormat]s for each [LinePattern] in [set].
  ///
  /// Patterns are converted to [LineGraphResult]s and optionally enriched
  /// with inline theory links before being flattened into spot seeds.
  List<SpotSeedFormat> expandLinePatterns(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) {
    if (_isManual(set)) return [];
    final seeds = <SpotSeedFormat>[];
    for (final pattern in set.linePatterns) {
      var result = _lineEngine.build(pattern);
      if (theoryIndex.isNotEmpty) {
        result = _theoryLinker.link(result, theoryIndex);
      }
      final villainActions = <String>[];
      const order = ['preflop', 'flop', 'turn', 'river'];
      for (final street in order) {
        final nodes = result.streets[street];
        if (nodes == null) continue;
        for (final node in nodes) {
          if (node.actor.toLowerCase() == 'villain') {
            villainActions.add(node.action);
          }
        }
      }

      var boardLen = 0;
      if (result.streets.containsKey('river')) {
        boardLen = 5;
      } else if (result.streets.containsKey('turn')) {
        boardLen = 4;
      } else if (result.streets.containsKey('flop')) {
        boardLen = 3;
      }
      final board = <CardModel>[];
      for (var i = 0; i < boardLen; i++) {
        board.add(CardModel(rank: 'X', suit: 'x'));
      }

      seeds.add(
        SpotSeedFormat(
          player: 'hero',
          handGroup: const [],
          position: result.heroPosition,
          board: board,
          villainActions: villainActions,
          tags: result.tags,
        ),
      );
    }
    return seeds;
  }

  /// Alias for [expandLinePatterns] kept for backwards compatibility.
  ///
  /// Delegates to [expandLinePatterns] and exists to provide a more
  /// descriptive method name for line-based expansions.
  List<SpotSeedFormat> expandLines(
    TrainingPackTemplateSet set, {
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) =>
      expandLinePatterns(set, theoryIndex: theoryIndex);

  /// Generates [SpotSeed]s from [TrainingPackTemplateSet.postflopLines].
  ///
  /// When the template defines one or more `postflopLines`, each is expanded
  /// into seeds per street using [LineGraphEngine.expandLine]. Each seed
  /// contains the accumulated action history up to that street.
  List<SpotSeed> expandPostflopLines(TrainingPackTemplateSet set) {
    if (_isManual(set) || set.postflopLines.isEmpty) return [];

    final handCards = <CardModel>[];
    for (final token in set.baseSpot.hand.heroCards.split(RegExp(r'\s+'))) {
      if (token.length >= 2) {
        handCards.add(CardModel(rank: token[0], suit: token[1]));
      }
    }
    final board = <CardModel>[
      for (final c in set.baseSpot.hand.board)
        CardModel(rank: c[0], suit: c.length > 1 ? c[1] : ''),
    ];

    final preset = set.boardTexturePreset;
    if (preset != null && preset.isNotEmpty) {
      if (!BoardTexturePresetLibrary.matches(board, preset)) {
        return [];
      }
    }

    for (final ex in set.excludeBoardTexturePresets) {
      if (BoardTexturePresetLibrary.matches(board, ex)) {
        return [];
      }
    }

    if (!BoardClusterConstraintEngine.matches(
      board: board,
      requiredClusters: set.requiredBoardClusters,
      excludedClusters: set.excludedBoardClusters,
    )) {
      return [];
    }

    final preActions = set.baseSpot.hand.actions[0] ?? [];
    final preflopAction = preActions.map((a) => a.action).join('-');

    final seeds = <SpotSeed>[];
    final lines = set.postflopLines;
    Iterable<PostflopLine> chosen;
    if (set.expandAllLines) {
      chosen = lines;
    } else {
      final total = lines.fold<int>(0, (s, l) => s + l.weight);
      final rng = Random(set.postflopLineSeed);
      final roll = rng.nextInt(total);
      var acc = 0;
      PostflopLine selected = lines.first;
      for (final l in lines) {
        acc += l.weight;
        if (roll < acc) {
          selected = l;
          break;
        }
      }
      chosen = [selected];
    }
    for (final entry in chosen) {
      if (entry.line.isEmpty) continue;
      seeds.addAll(
        _lineEngine.expandLine(
          preflopAction: preflopAction,
          line: entry.line,
          board: board,
          hand: handCards,
          position: set.baseSpot.hand.position.name,
        ),
      );
    }
    return seeds;
  }

  /// Backwards compatible alias for [expandPostflopLines].
  List<SpotSeed> expandPostflopLine(TrainingPackTemplateSet set) =>
      expandPostflopLines(set);
}
