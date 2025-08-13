import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

class CoverageSummary {
  final int ev;
  final int icm;
  final int total;

  const CoverageSummary(
      {required this.ev, required this.icm, required this.total});

  void applyTo(Map<String, dynamic> meta) {
    meta['evCovered'] = ev;
    meta['icmCovered'] = icm;
    meta['totalWeight'] = total;
  }
}

class TemplateCoverageUtils {
  static CoverageSummary recountAll(TrainingPackTemplateV2 template) {
    final List<TrainingPackSpot> list = template.spots;
    int ev = 0;
    int icm = 0;
    int total = 0;
    for (final s in list) {
      final w = s.priority;
      total += w;
      if (s.heroEv != null) ev += w;
      if (s.heroIcmEv != null) icm += w;
    }
    return CoverageSummary(ev: ev, icm: icm, total: total);
  }
}
