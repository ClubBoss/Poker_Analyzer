import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';

class PackTemplateRefactorEngine {
  const PackTemplateRefactorEngine();

  TrainingPackTemplateV2 refactor(TrainingPackTemplateV2 pack) {
    final tagSet = <String>{};
    for (final t in pack.tags) {
      final v = t.trim();
      if (v.isNotEmpty) tagSet.add(v);
    }
    pack.tags = tagSet.toList()..sort();
    final meta = <String, dynamic>{};
    meta.addAll(pack.meta);
    final kw = meta['keywords'];
    final keywords = <String>{};
    if (kw is List) {
      for (final v in kw) {
        if (v is String && v.trim().isNotEmpty) keywords.add(v.trim());
      }
    } else if (kw is String) {
      for (final v in kw.split(RegExp(r'[;, ]+'))) {
        final s = v.trim();
        if (s.isNotEmpty) keywords.add(s);
      }
    }
    if (keywords.isEmpty) {
      meta.remove('keywords');
    } else {
      meta['keywords'] = keywords.toList()..sort();
    }
    meta.removeWhere(
      (k, v) =>
          v == null ||
          (v is String && v.isEmpty) ||
          (v is List && v.isEmpty) ||
          (v is Map && v.isEmpty),
    );
    meta['schemaVersion'] = '2.0.0';
    pack.meta
      ..clear()
      ..addAll(meta);
    pack.spots.sort(_spotCompare);
    pack.spotCount = pack.spots.length;
    return pack;
  }

  Map<String, dynamic> orderedJson(TrainingPackTemplateV2 tpl) {
    final json = tpl.toJson();
    final map = <String, dynamic>{};
    for (final k in ['id', 'name', 'tags', 'meta', 'spots']) {
      if (json.containsKey(k)) map[k] = json.remove(k);
    }
    for (final e in json.entries) {
      map[e.key] = e.value;
    }
    return map;
  }

  int _spotCompare(TrainingPackSpot a, TrainingPackSpot b) {
    final sa = a.hand.stacks['${a.hand.heroIndex}'] ?? 0;
    final sb = b.hand.stacks['${b.hand.heroIndex}'] ?? 0;
    final c = sa.compareTo(sb);
    if (c != 0) return c;
    final pa = kPositionOrder.indexOf(a.hand.position);
    final pb = kPositionOrder.indexOf(b.hand.position);
    return pa.compareTo(pb);
  }
}
