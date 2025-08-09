import '../models/constraint_set.dart';
import '../models/spot_seed_format.dart';
import '../models/card_model.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../utils/board_analyzer_utils.dart';
import '../utils/stack_utils.dart';
import 'action_pattern_matcher.dart';
import 'package:uuid/uuid.dart';

class ConstraintResolverEngine {
  final ActionPatternMatcher _actionMatcher;

  const ConstraintResolverEngine({ActionPatternMatcher? actionMatcher})
    : _actionMatcher = actionMatcher ?? const ActionPatternMatcher();

  bool isValid(SpotSeedFormat candidate, ConstraintSet constraints) {
    final posReq = constraints.position?.toLowerCase();
    if (posReq != null && candidate.position.toLowerCase() != posReq) {
      return false;
    }
    if (posReq == null &&
        constraints.positions.isNotEmpty &&
        !constraints.positions
            .map((e) => e.toLowerCase())
            .contains(candidate.position.toLowerCase())) {
      return false;
    }

    final oppReq = constraints.opponentPosition?.toLowerCase();
    if (oppReq != null) {
      final opp = candidate.opponentPosition?.toLowerCase();
      if (opp != oppReq) return false;
    }

    if (constraints.handGroup.isNotEmpty &&
        !candidate.handGroup.any(
          (h) => constraints.handGroup
              .map((e) => e.toLowerCase())
              .contains(h.toLowerCase()),
        )) {
      return false;
    }

    final boardTags = BoardAnalyzerUtils.tags(
      candidate.board,
    ).map((t) => t.toLowerCase()).toSet();
    if (constraints.boardTags.isNotEmpty) {
      final required = constraints.boardTags
          .map((t) => t.toLowerCase())
          .toList();
      if (!required.every(boardTags.contains)) {
        return false;
      }
    }
    if (constraints.boardTexture != null) {
      final req = (constraints.boardTexture!['requiredTags'] as List? ?? [])
          .map((e) => e.toString().toLowerCase());
      if (!req.every(boardTags.contains)) return false;
      final excl = (constraints.boardTexture!['excludedTags'] as List? ?? [])
          .map((e) => e.toString().toLowerCase());
      if (excl.any(boardTags.contains)) return false;
    }

    if (constraints.requiredTags.isNotEmpty) {
      final tags = candidate.tags.map((t) => t.toLowerCase()).toSet();
      final req = constraints.requiredTags.map((t) => t.toLowerCase()).toList();
      if (!req.every(tags.contains)) return false;
    }
    if (constraints.excludedTags.isNotEmpty) {
      final tags = candidate.tags.map((t) => t.toLowerCase()).toSet();
      final excl = constraints.excludedTags
          .map((t) => t.toLowerCase())
          .toList();
      if (excl.any(tags.contains)) return false;
    }

    if (constraints.villainActions.isNotEmpty &&
        !_actionMatcher.matches(
          candidate.villainActions,
          constraints.villainActions,
        )) {
      return false;
    }

    if (constraints.targetStreet != null &&
        constraints.targetStreet!.isNotEmpty &&
        candidate.currentStreet.toLowerCase() !=
            constraints.targetStreet!.toLowerCase()) {
      return false;
    }

    if (constraints.minStack != null || constraints.maxStack != null) {
      final stack = candidate.heroStack;
      if (stack == null ||
          !StackUtils.inRange(
            stack,
            min: constraints.minStack,
            max: constraints.maxStack,
          )) {
        return false;
      }
    }

    return true;
  }

  /// Applies [sets] to [base] producing all valid [TrainingPackSpot]
  /// variations. Each [ConstraintSet] may define multiple override options via
  /// [ConstraintSet.overrides]; the cartesian product of those options is
  /// generated and applied to the base spot. Tags, theory links and metadata are
  /// merged or overridden according to the `MergeMode` settings.
  List<TrainingPackSpot> apply(
    TrainingPackSpot base,
    List<ConstraintSet> sets, {
    Random? rng,
  }) {
    if (sets.isEmpty) {
      return [_cloneBase(base, rng: rng)];
    }

    final results = <TrainingPackSpot>[];
    for (final set in sets) {
      final combos = _cartesian(set.overrides);
      for (final combo in combos) {
        final spot = _cloneBase(base, rng: rng);

        combo.forEach((key, value) {
          switch (key) {
            case 'board':
              final board = [for (final c in value as List) c.toString()];
              spot.board = board;
              spot.hand.board = List<String>.from(board);
              break;
            case 'heroStack':
              final stack = (value as num).toDouble();
              spot.hand.stacks = {...spot.hand.stacks, '0': stack};
              break;
            case 'heroPosition':
            case 'position':
              spot.hand.position = parseHeroPosition(value.toString());
              break;
            case 'tags':
              final tags = [for (final t in value as List) t.toString()];
              spot.tags = _mergeTags(spot.tags, tags, set.tagMergeMode);
              break;
            default:
              spot.meta[key] = value;
          }
        });

        // Apply constant tag/meta overrides from the set.
        spot.tags = _mergeTags(spot.tags, set.tags, set.tagMergeMode);
        spot.meta = _mergeMeta(spot.meta, set.metadata, set.metaMergeMode);
        if (set.theoryLink != null) {
          spot.theoryLink = set.theoryLink;
        }

        final seed = _toSeed(spot);
        if (isValid(seed, set)) {
          results.add(spot);
        }
      }
    }

    return results;
  }

  TrainingPackSpot _cloneBase(TrainingPackSpot base, {Random? rng}) {
    final json = Map<String, dynamic>.from(base.toJson());
    json['id'] = rng == null
        ? const Uuid().v4()
        : const Uuid().v4(
            config: {
              'rng': () => List<int>.generate(16, (_) => rng.nextInt(256)),
            },
          );
    final copy = TrainingPackSpot.fromJson(json);
    copy.templateSourceId = base.id;
    copy.tags = List<String>.from(base.tags);
    copy.theoryLink = base.theoryLink;
    copy.meta = Map<String, dynamic>.from(base.meta);
    return copy;
  }

  List<Map<String, dynamic>> _cartesian(Map<String, List<dynamic>> input) {
    var result = <Map<String, dynamic>>[{}];
    input.forEach((key, values) {
      final next = <Map<String, dynamic>>[];
      for (final combo in result) {
        for (final v in values) {
          final map = Map<String, dynamic>.from(combo);
          map[key] = v;
          next.add(map);
        }
      }
      result = next;
    });
    return result;
  }

  List<String> _mergeTags(
    List<String> base,
    List<String> updates,
    MergeMode mode,
  ) {
    final set = <String>{};
    if (mode == MergeMode.add) {
      set.addAll(base);
    }
    set.addAll(updates);
    return set.toList();
  }

  Map<String, dynamic> _mergeMeta(
    Map<String, dynamic> base,
    Map<String, dynamic> updates,
    MergeMode mode,
  ) {
    if (mode == MergeMode.override) {
      return Map<String, dynamic>.from(updates);
    }
    return {...base, ...updates};
  }

  SpotSeedFormat _toSeed(TrainingPackSpot spot) {
    final board = [
      for (final c in spot.board)
        CardModel(rank: c[0], suit: c.length > 1 ? c[1] : ''),
    ];
    final heroPos = spot.hand.position.name;
    final stack = spot.hand.stacks['0'];
    final actions = <String>[];
    if (spot.villainAction != null && spot.villainAction!.isNotEmpty) {
      actions.add(spot.villainAction!.split(' ').first);
    }
    return SpotSeedFormat(
      player: 'hero',
      handGroup: const [],
      position: heroPos,
      opponentPosition: null,
      heroStack: stack,
      board: board,
      villainActions: actions,
      tags: spot.tags,
    );
  }
}
