import '../models/constraint_set.dart';
import '../models/spot_seed_format.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import 'action_pattern_matcher.dart';
import 'dynamic_board_tagger_service.dart';
import 'package:uuid/uuid.dart';

class ConstraintResolverEngine {
  final DynamicBoardTaggerService _tagger;
  final ActionPatternMatcher _actionMatcher;

  const ConstraintResolverEngine({
    DynamicBoardTaggerService? tagger,
    ActionPatternMatcher? actionMatcher,
  })  : _tagger = tagger ?? const DynamicBoardTaggerService(),
        _actionMatcher = actionMatcher ?? const ActionPatternMatcher();

  bool isValid(SpotSeedFormat candidate, ConstraintSet constraints) {
    if (constraints.positions.isNotEmpty &&
        !constraints.positions
            .map((e) => e.toLowerCase())
            .contains(candidate.position.toLowerCase())) {
      return false;
    }

    if (constraints.handGroup.isNotEmpty &&
        !candidate.handGroup.any(
          (h) => constraints.handGroup
              .map((e) => e.toLowerCase())
              .contains(h.toLowerCase()),
        )) {
      return false;
    }

    if (constraints.boardTags.isNotEmpty) {
      final actualTags =
          _tagger.tag(candidate.board).map((t) => t.toLowerCase()).toSet();
      final required =
          constraints.boardTags.map((t) => t.toLowerCase()).toList();
      if (!required.every(actualTags.contains)) {
        return false;
      }
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

    return true;
  }

  /// Applies [sets] to [base] producing all valid [TrainingPackSpot]
  /// variations. Each [ConstraintSet] may define multiple override options via
  /// [ConstraintSet.overrides]; the cartesian product of those options is
  /// generated and applied to the base spot. Tags, theory links and metadata are
  /// merged or overridden according to the `MergeMode` settings.
  List<TrainingPackSpot> apply(
    TrainingPackSpot base,
    List<ConstraintSet> sets,
  ) {
    if (sets.isEmpty) {
      return [_cloneBase(base)];
    }

    final results = <TrainingPackSpot>[];
    for (final set in sets) {
      final combos = _cartesian(set.overrides);
      for (final combo in combos) {
        final spot = _cloneBase(base);

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

        results.add(spot);
      }
    }

    return results;
  }

  TrainingPackSpot _cloneBase(TrainingPackSpot base) {
    final json = Map<String, dynamic>.from(base.toJson());
    json['id'] = const Uuid().v4();
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
}
