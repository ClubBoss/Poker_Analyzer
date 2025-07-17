import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class YamlPackMergeEngine {
  final Uuid _uuid;
  const YamlPackMergeEngine({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  TrainingPackTemplateV2 merge(
    TrainingPackTemplateV2 a,
    TrainingPackTemplateV2 b,
  ) {
    final id = _uuid.v4();
    final tags = <String>{...a.tags, ...b.tags}
      ..removeWhere((e) => e.trim().isEmpty);
    final spots = <TrainingPackSpot>[];
    final keys = <String>{};
    String key(TrainingPackSpot s) =>
        '${s.hand.toJson()}|${s.correctAction}|${s.explanation}';
    void add(TrainingPackSpot s) {
      final k = key(s);
      if (keys.add(k)) spots.add(s);
    }

    for (final s in a.spots) add(s);
    for (final s in b.spots) add(s);

    final meta = <String, dynamic>{...a.meta};
    b.meta.forEach((k, v) => meta.putIfAbsent(k, () => v));
    double? avg(String k) {
      final x = (a.meta[k] as num?)?.toDouble();
      final y = (b.meta[k] as num?)?.toDouble();
      if (x != null && y != null) return (x + y) / 2;
      return x ?? y;
    }
    final evScore = avg('evScore');
    final icmScore = avg('icmScore');
    if (evScore != null) meta['evScore'] = evScore;
    if (icmScore != null) meta['icmScore'] = icmScore;

    var ev = 0;
    var icm = 0;
    var total = 0;
    for (final s in spots) {
      final w = s.priority;
      total += w;
      if (!s.dirty && s.heroEv != null) ev += w;
      if (!s.dirty && s.heroIcmEv != null) icm += w;
    }
    meta['evCovered'] = ev;
    meta['icmCovered'] = icm;
    meta['totalWeight'] = total;

    return TrainingPackTemplateV2(
      id: id,
      name: '${a.name} + ${b.name}',
      description: a.description.isNotEmpty ? a.description : b.description,
      goal: a.goal.isNotEmpty ? a.goal : b.goal,
      audience: a.audience?.isNotEmpty == true ? a.audience : b.audience,
      tags: tags.toList(),
      category: a.category ?? b.category,
      type: a.type,
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: a.gameType,
      bb: a.bb,
      positions: {...a.positions, ...b.positions}.toList(),
      meta: meta,
      recommended: a.recommended || b.recommended,
    );
  }
}
