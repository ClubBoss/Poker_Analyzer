import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/spot_template.dart';

class YamlPackConflict {
  final TrainingPackTemplateV2 packA;
  final TrainingPackTemplateV2 packB;
  final String type;
  final double similarityScore;
  YamlPackConflict({
    required this.packA,
    required this.packB,
    required this.type,
    required this.similarityScore,
  });
}

class YamlPackConflictDetector {
  YamlPackConflictDetector();

  List<YamlPackConflict> detectConflicts(List<TrainingPackTemplateV2> packs) {
    final conflicts = <YamlPackConflict>[];
    final ids = <String, TrainingPackTemplateV2>{};
    final names = <String, TrainingPackTemplateV2>{};
    for (final p in packs) {
      final id = p.id.trim();
      final name = p.name.trim().toLowerCase();
      final idPrev = ids[id];
      if (idPrev != null) {
        conflicts.add(
          YamlPackConflict(
            packA: idPrev,
            packB: p,
            type: 'duplicate_id',
            similarityScore: 1,
          ),
        );
      } else {
        ids[id] = p;
      }
      final namePrev = names[name];
      if (namePrev != null) {
        conflicts.add(
          YamlPackConflict(
            packA: namePrev,
            packB: p,
            type: 'duplicate_name',
            similarityScore: 1,
          ),
        );
      } else {
        names[name] = p;
      }
    }
    for (var i = 0; i < packs.length; i++) {
      final a = packs[i];
      for (var j = i + 1; j < packs.length; j++) {
        final b = packs[j];
        final sim = _spotSimilarity(a.spots, b.spots);
        if (sim >= 0.8) {
          conflicts.add(
            YamlPackConflict(
              packA: a,
              packB: b,
              type: 'similar_spots',
              similarityScore: sim,
            ),
          );
        } else if ((a.audience ?? '') == (b.audience ?? '') && sim >= 0.5) {
          conflicts.add(
            YamlPackConflict(
              packA: a,
              packB: b,
              type: 'audience_overlap',
              similarityScore: sim,
            ),
          );
        }
      }
    }
    conflicts.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return conflicts;
  }

  double _spotSimilarity(List<SpotTemplate> a, List<SpotTemplate> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final setA = {for (final s in a) _spotKey(s)};
    final setB = {for (final s in b) _spotKey(s)};
    final minLen = setA.length < setB.length ? setA.length : setB.length;
    var common = 0;
    for (final k in setA) {
      if (setB.contains(k)) common++;
    }
    if (minLen == 0) return 0;
    return common / minLen;
  }

  String _spotKey(SpotTemplate s) {
    final map = Map<String, dynamic>.from(s.toJson());
    map.remove('editedAt');
    map.remove('createdAt');
    map.remove('evalResult');
    map.remove('correctAction');
    map.remove('explanation');
    return map.toString();
  }
}
