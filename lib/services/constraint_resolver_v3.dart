import '../models/constraint_set.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import 'full_board_generator_v2.dart';
import 'line_graph_engine.dart';
import 'package:uuid/uuid.dart';
import 'board_texture_preset_library.dart';

/// Resolves [ConstraintSet] variations against a base [TrainingPackSpot]
/// producing fully realized training spots. Supports hybrid line pattern and
/// board constraint expansion within the same variation block.
class ConstraintResolverV3 {
  final FullBoardGeneratorV2 _boardGenerator;
  final LineGraphEngine _lineEngine;
  final Uuid _uuid;

  const ConstraintResolverV3({
    FullBoardGeneratorV2? boardGenerator,
    LineGraphEngine? lineEngine,
    Uuid? uuid,
  })
      : _boardGenerator = boardGenerator ?? const FullBoardGeneratorV2(),
        _lineEngine = lineEngine ?? LineGraphEngine(),
        _uuid = uuid ?? const Uuid();

  /// Applies [sets] to [base] producing all valid [TrainingPackSpot]
  /// variations. Each set may contain board generation rules via
  /// [ConstraintSet.boardConstraints] and an optional [ConstraintSet.linePattern]
  /// to describe action sequences. The cartesian product of override values is
  /// expanded and combined with line pattern results.
  List<TrainingPackSpot> apply(
    TrainingPackSpot base,
    List<ConstraintSet> sets,
  ) {
    if (sets.isEmpty) {
      return [_cloneBase(base)];
    }

    final results = <TrainingPackSpot>[];
    for (final set in sets) {
      final expanded = _expandBoards(set);
      final combos = _cartesian(expanded.overrides);
      if (combos.isEmpty) combos.add({});
      final lineResult = expanded.linePattern != null
          ? _lineEngine.build(expanded.linePattern!)
          : null;
      final villainActions = <String>[];
      if (lineResult != null) {
        const order = ['preflop', 'flop', 'turn', 'river'];
        for (final street in order) {
          final nodes = lineResult.streets[street];
          if (nodes == null) continue;
          for (final node in nodes) {
            if (node.actor.toLowerCase() == 'villain') {
              villainActions.add(node.action);
            }
          }
        }
      }

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

        // Apply line pattern results.
        if (lineResult != null) {
          spot.hand.position =
              parseHeroPosition(lineResult.heroPosition.toString());
          if (villainActions.isNotEmpty) {
            spot.villainAction = villainActions.last;
          }
          if (lineResult.streets.containsKey('river')) {
            spot.street = 3;
          } else if (lineResult.streets.containsKey('turn')) {
            spot.street = 2;
          } else if (lineResult.streets.containsKey('flop')) {
            spot.street = 1;
          }
          spot.tags = _mergeTags(spot.tags, lineResult.tags, MergeMode.add);
        }

        // Determine street override based on targetStreet if provided.
        if (expanded.targetStreet != null) {
          switch (expanded.targetStreet!.toLowerCase()) {
            case 'flop':
              spot.street = 1;
              break;
            case 'turn':
              spot.street = 2;
              break;
            case 'river':
              spot.street = 3;
              break;
          }
        } else if (spot.street == 0 && spot.board.isNotEmpty) {
          if (spot.board.length >= 5) {
            spot.street = 3;
          } else if (spot.board.length == 4) {
            spot.street = 2;
          } else if (spot.board.length == 3) {
            spot.street = 1;
          }
        }

        results.add(spot);
      }
    }
    return results;
  }

  ConstraintSet _expandBoards(ConstraintSet set) {
    if (set.boardConstraints.isEmpty) {
      return set;
    }
    final overrides = Map<String, List<dynamic>>.from(set.overrides);
    final boards = <List<String>>[];
    String? streetOverride = set.targetStreet;
    for (final params in set.boardConstraints) {
      var map = Map<String, dynamic>.from(params);
      final preset = map.remove('preset');
      if (preset != null) {
        final expanded =
            BoardTexturePresetLibrary.get(preset.toString());
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
        requiredBoardClusters: paramRequired,
        excludedBoardClusters: paramExcluded,
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

  TrainingPackSpot _cloneBase(TrainingPackSpot base) {
    final json = Map<String, dynamic>.from(base.toJson());
    json['id'] = _uuid.v4();
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
