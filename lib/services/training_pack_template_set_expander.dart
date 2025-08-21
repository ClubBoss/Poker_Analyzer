import 'dart:convert';

import '../models/v2/training_pack_template_set.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/spot_seed_format.dart';
import '../models/card_model.dart';
import 'constraint_resolver_engine_v2.dart';

/// Expands a [TrainingPackTemplateSet] into concrete [TrainingPackTemplateV2]
/// instances using [ConstraintResolverEngine]. Each entry in the set produces
/// a new template whose spots are filtered by the entry's constraint delta.
class TrainingPackTemplateSetExpander {
  final ConstraintResolverEngine _engine;

  const TrainingPackTemplateSetExpander({ConstraintResolverEngine? engine})
      : _engine = engine ?? const ConstraintResolverEngine();

  /// Generates pack templates defined by [set].
  List<TrainingPackTemplateV2> expand(TrainingPackTemplateSet set) {
    if (set.entries.isEmpty) {
      return [];
    }
    final baseMap =
        jsonDecode(jsonEncode(set.template.toJson())) as Map<String, dynamic>;
    final result = <TrainingPackTemplateV2>[];
    for (var i = 0; i < set.entries.length; i++) {
      final entry = set.entries[i];
      final map = Map<String, dynamic>.from(baseMap);
      map['name'] = entry.name;
      if (map['id'] is String) {
        map['id'] = '${map['id']}_${_slug(entry.name)}';
      }
      final tpl = TrainingPackTemplateV2.fromJson(map);
      if (entry.tags.isNotEmpty) {
        final tagSet = {...tpl.tags, ...entry.tags};
        tpl.tags = tagSet.toList()..sort();
      }
      tpl.meta['origin'] = 'template-set';
      final spots = <TrainingPackSpot>[];
      for (final s in set.template.spots) {
        final candidate = _toSeed(s);
        if (_engine.isValid(candidate, entry.constraints)) {
          spots.add(
            TrainingPackSpot.fromJson(Map<String, dynamic>.from(s.toJson())),
          );
        }
      }
      tpl.spots = spots;
      tpl.spotCount = spots.length;
      result.add(tpl);
    }
    return result;
  }

  /// Convenience method to parse [yaml] and expand it into pack templates.
  List<TrainingPackTemplateV2> expandFromYaml(String yaml) {
    final set = TrainingPackTemplateSet.fromYaml(yaml);
    return expand(set);
  }

  SpotSeedFormat _toSeed(TrainingPackSpot spot) {
    final board = [
      for (final c in spot.board)
        CardModel(rank: c[0], suit: c.length > 1 ? c[1] : ''),
    ];
    final heroPos = spot.hand.position.name;
    final actions = <String>[];
    if (spot.villainAction != null && spot.villainAction!.isNotEmpty) {
      actions.add(spot.villainAction!.split(' ').first);
    }
    final stack = spot.hand.stacks['0'];
    return SpotSeedFormat(
      player: 'hero',
      handGroup: const [],
      position: heroPos,
      heroStack: stack,
      board: board,
      villainActions: actions,
      tags: spot.tags,
    );
  }

  String _slug(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
