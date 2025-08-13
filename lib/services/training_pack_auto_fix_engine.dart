import '../models/v2/training_pack_template_v2.dart';
import '../models/yaml_pack_review_report.dart';

class TrainingPackAutoFixEngine {
  const TrainingPackAutoFixEngine();

  TrainingPackTemplateV2 autoFix(
    TrainingPackTemplateV2 pack,
    YamlPackReviewReport report,
  ) {
    if (pack.goal.trim().isEmpty) pack.goal = 'TBD';
    final tags = <String>{};
    for (final t in pack.tags) {
      final v = t.trim();
      if (v.isEmpty || _badTag(v)) continue;
      tags.add(v);
    }
    pack.tags = tags.toList();
    if (pack.audience == null || pack.audience!.trim().isEmpty) {
      pack.audience = 'Unknown';
    }
    if (pack.category == null || pack.category!.trim().isEmpty) {
      pack.category = 'Unknown';
    }
    if (pack.positions.isEmpty) pack.positions = ['Unknown'];
    _recountCoverage(pack);
    final double? evScore = (pack.meta['evScore'] as num?)?.toDouble();
    final double? icmScore = (pack.meta['icmScore'] as num?)?.toDouble();
    if (evScore == null || evScore < 0 || evScore > 100) {
      pack.meta['evScore'] = 0;
    }
    if (icmScore == null || icmScore < 0 || icmScore > 100) {
      pack.meta['icmScore'] = 0;
    }
    if (pack.meta['totalWeight'] is! num ||
        (pack.meta['totalWeight'] as num) <= 0) {
      pack.meta['totalWeight'] = pack.spotCount;
    }
    pack.spotCount = pack.spots.length;
    return pack;
  }

  void _recountCoverage(TrainingPackTemplateV2 pack) {
    var ev = 0;
    var icm = 0;
    var total = 0;
    for (final s in pack.spots) {
      final w = s.priority;
      total += w;
      if (s.heroEv != null) ev += w;
      if (s.heroIcmEv != null) icm += w;
    }
    pack.meta['evCovered'] = ev;
    pack.meta['icmCovered'] = icm;
    pack.meta['totalWeight'] = total;
  }

  bool _badTag(String t) {
    final v = t.trim();
    if (v.isEmpty) return true;
    if (v.startsWith('old') || v.startsWith('tmp')) return true;
    if (v.length > 20) return true;
    return false;
  }
}
