import 'dart:convert';

import '../models/v2/training_pack_template_set.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/spot_seed_format.dart';
import '../models/card_model.dart';
import 'constraint_resolver_engine_v2.dart';

/// Expands a [TrainingPackTemplateSet] into concrete [TrainingPackTemplateV2]
/// instances. Supports both legacy mustache-style interpolation and
/// constraint-based template set entries.
class TrainingPackTemplateSetGenerator {
  const TrainingPackTemplateSetGenerator();

  /// Generates all packs defined by [set]. Supports both legacy mustache
  /// variants and the new constraint-based [TemplateSetEntry] expansions.
  List<TrainingPackTemplateV2> generate(TrainingPackTemplateSet set) {
    if (set.entries.isNotEmpty) {
      return _generateFromEntries(set);
    }
    final baseJson = jsonEncode(set.template.toJson());
    final result = <TrainingPackTemplateV2>[];
    for (final variant in set.variants) {
      var json = baseJson;
      variant.forEach((key, value) {
        json = json.replaceAll('{{${key}}}', value.toString());
      });
      final map = jsonDecode(json) as Map<String, dynamic>;
      result.add(TrainingPackTemplateV2.fromJson(map));
    }
    return result;
  }

  List<TrainingPackTemplateV2> _generateFromEntries(
    TrainingPackTemplateSet set,
  ) {
    final engine = ConstraintResolverEngine();
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
      final spots = <TrainingPackSpot>[];
      for (final s in set.template.spots) {
        final candidate = _toSeed(s);
        if (engine.isValid(candidate, entry.constraints)) {
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
    return SpotSeedFormat(
      player: 'hero',
      handGroup: const [],
      position: heroPos,
      board: board,
      villainActions: actions,
    );
  }

  String _slug(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  /// Parses [yaml] and generates all packs from it.
  List<TrainingPackTemplateV2> generateFromYaml(String yaml) {
    final set = TrainingPackTemplateSet.fromYaml(yaml);
    return generate(set);
  }
}
