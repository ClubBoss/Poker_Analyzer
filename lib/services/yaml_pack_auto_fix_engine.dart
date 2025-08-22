import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import 'yaml_pack_changelog_service.dart';

class YamlPackAutoFixEngine {
  final Uuid _uuid;
  YamlPackAutoFixEngine({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  TrainingPackTemplateV2 autoFix(TrainingPackTemplateV2 pack) {
    final id = pack.id.trim().isEmpty ? _uuid.v4() : pack.id;
    final meta = Map<String, dynamic>.from(pack.meta);
    meta.putIfAbsent('schemaVersion', () => '2.0.0');

    final positions = <String>{};
    for (final p in pack.positions) {
      final pos = parseHeroPosition(p);
      if (pos != HeroPosition.unknown) positions.add(pos.name);
    }

    final ids = <String>{};
    final spots = <TrainingPackSpot>[];
    for (final s in pack.spots) {
      final sid = s.id.trim();
      if (sid.isEmpty || !ids.add(sid)) continue;
      if (s.hand.position == HeroPosition.unknown) continue;
      if (s.explanation == null || s.explanation!.trim().isEmpty) {
        s.explanation = 'TBD';
      }
      spots.add(s);
    }

    final result = TrainingPackTemplateV2(
      id: id,
      name: pack.name,
      description: pack.description,
      goal: pack.goal,
      audience: pack.audience,
      tags: List<String>.from(pack.tags),
      category: pack.category,
      trainingType: pack.trainingType,
      spots: spots,
      spotCount: spots.length,
      created: pack.created,
      gameType: pack.gameType,
      bb: pack.bb,
      positions: positions.toList(),
      meta: meta,
      recommended: pack.recommended,
    );
    unawaited(
      YamlPackChangelogService().appendChangeLog(
        result,
        'Автофикс: добавлены id, удалены дубликаты',
      ),
    );
    return result;
  }
}
