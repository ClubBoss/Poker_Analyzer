import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';

class TemplateCoverageUtils {
  static void recountAll(TrainingPackTemplate template) {
    final List<TrainingPackSpot> list = template.spots;
    int ev = 0;
    int icm = 0;
    int total = 0;
    for (final s in list) {
      final w = s.priority;
      total += w;
      if (!s.dirty && s.heroEv != null) ev += w;
      if (!s.dirty && s.heroIcmEv != null) icm += w;
    }
    template.meta['evCovered'] = ev;
    template.meta['icmCovered'] = icm;
    template.meta['totalWeight'] = total;
  }
}
