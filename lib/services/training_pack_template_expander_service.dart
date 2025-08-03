import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/constraint_set.dart';
import 'constraint_resolver_engine_v2.dart';
import 'auto_spot_theory_injector_service.dart';
import 'full_board_generator.dart';

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

  TrainingPackTemplateExpanderService({
    ConstraintResolverEngine? engine,
    AutoSpotTheoryInjectorService? injector,
    FullBoardGenerator? boardGenerator,
  })  : _engine = engine ?? const ConstraintResolverEngine(),
        _injector = injector ?? AutoSpotTheoryInjectorService(),
        _boardGenerator = boardGenerator ?? const FullBoardGenerator();

  /// Generates all spots described by [set] and injects theory links.
  List<TrainingPackSpot> expand(TrainingPackTemplateSet set) {
    final processed = [
      for (final v in set.variations) _expandBoards(v),
    ];
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
}
