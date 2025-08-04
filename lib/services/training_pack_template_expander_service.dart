import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/constraint_set.dart';
import '../models/spot_seed_format.dart';
import '../models/card_model.dart';
import '../models/inline_theory_entry.dart';
import 'constraint_resolver_engine_v2.dart';
import 'auto_spot_theory_injector_service.dart';
import 'full_board_generator.dart';
import 'line_graph_engine.dart';
import 'inline_theory_node_linker.dart';

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
  final FullBoardGenerator _boardGenerator;
  final LineGraphEngine _lineEngine;
  final InlineTheoryNodeLinker _theoryLinker;

  TrainingPackTemplateExpanderService({
    ConstraintResolverEngine? engine,
    AutoSpotTheoryInjectorService? injector,
    FullBoardGenerator? boardGenerator,
    LineGraphEngine? lineEngine,
    InlineTheoryNodeLinker? theoryLinker,
  }) : _engine = engine ?? const ConstraintResolverEngine(),
       _injector = injector ?? AutoSpotTheoryInjectorService(),
       _boardGenerator = boardGenerator ?? const FullBoardGenerator(),
       _lineEngine = lineEngine ?? const LineGraphEngine(),
       _theoryLinker = theoryLinker ?? const InlineTheoryNodeLinker();

  /// Generates all spots described by [set] and injects theory links.
  List<TrainingPackSpot> expand(TrainingPackTemplateSet set) {
    final processed = [for (final v in set.variations) _expandBoards(v)];
    final spots = _engine.apply(set.baseSpot, processed);
    _injector.injectAll(spots);
    return spots;
  }

  ConstraintSet _expandBoards(ConstraintSet set) {
    final constraintKey = 'boardConstraints';
    if (!set.overrides.containsKey(constraintKey)) {
      return set;
    }
    final overrides = Map<String, List<dynamic>>.from(set.overrides);
    final constraintValues = overrides.remove(constraintKey)!;
    final boards = <List<String>>[];
    String? streetOverride = set.targetStreet;
    for (final c in constraintValues) {
      if (c is Map<String, dynamic>) {
        final params = Map<String, dynamic>.from(c);
        final street = params.remove('targetStreet')?.toString().toLowerCase();
        if (street != null) streetOverride = street;
        final generated = _boardGenerator.generate(params);
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
}
