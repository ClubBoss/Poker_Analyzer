import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../core/training/engine/training_type_engine.dart';

class YamlPackMergeEngine {
  final Uuid _uuid;
  YamlPackMergeEngine({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  TrainingPackTemplateV2 merge(List<TrainingPackTemplateV2> packs) {
    final list = packs.where((p) => p.spots.isNotEmpty).toList();
    if (list.isEmpty) {
      return TrainingPackTemplateV2(
        id: _uuid.v4(),
        name: 'Combined Pack',
        description: 'Combined Pack',
        trainingType: TrainingType.pushFold,
      );
    }
    final first = list.first;
    final id = _uuid.v4();
    final tags = <String>{};
    final keywords = <String>{};
    final spots = <TrainingPackSpot>[];
    final spotKeys = <String>{};
    for (final p in list) {
      for (final t in p.tags) {
        final v = t.trim();
        if (v.isNotEmpty) tags.add(v);
      }
      final kw = p.meta['keywords'];
      if (kw is List) {
        for (final v in kw) {
          if (v is String && v.trim().isNotEmpty) keywords.add(v.trim());
        }
      } else if (kw is String) {
        for (final v in kw.split(RegExp(r'[;, ]+'))) {
          final w = v.trim();
          if (w.isNotEmpty) keywords.add(w);
        }
      }
      for (final s in p.spots) {
        final k = s.hand.toJson().toString();
        if (spotKeys.add(k)) spots.add(s);
      }
    }

    final meta = <String, dynamic>{'schemaVersion': '2.0.0'};
    double evScore = 0;
    double icmScore = 0;
    var count = 0;
    for (final p in list) {
      p.meta.forEach((k, v) {
        meta.putIfAbsent(k, () => v);
      });
      final ev = (p.meta['evScore'] as num?)?.toDouble();
      final icm = (p.meta['icmScore'] as num?)?.toDouble();
      if (ev != null) {
        evScore += ev;
        count++;
      }
      if (icm != null) {
        icmScore += icm;
      }
    }
    if (count > 0) {
      meta['evScore'] = evScore / count;
      meta['icmScore'] = icmScore / count;
    }
    meta['keywords'] = keywords.toList();

    var ev = 0;
    var icm = 0;
    var total = 0;
    for (final s in spots) {
      final w = s.priority;
      total += w;
      if (s.heroEv != null) ev += w;
      if (s.heroIcmEv != null) icm += w;
    }
    meta['evCovered'] = ev;
    meta['icmCovered'] = icm;
    meta['totalWeight'] = total;

    return TrainingPackTemplateV2(
      id: id,
      name: 'Combined Pack',
      description: 'Combined Pack',
      goal: first.goal,
      audience: first.audience,
      tags: tags.toList(),
      category: first.category,
      trainingType: first.trainingType,
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: first.gameType,
      bb: first.bb,
      positions: {for (final p in list) ...p.positions}.toList(),
      meta: meta,
      recommended: list.any((p) => p.recommended),
    );
  }

  TrainingPackTemplateV2 mergeTwo(
    TrainingPackTemplateV2 a,
    TrainingPackTemplateV2 b,
  ) => merge([a, b]);
}
