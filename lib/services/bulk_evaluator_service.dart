import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import 'push_fold_ev_service.dart';

class BulkEvaluatorService {
  const BulkEvaluatorService({this.evaluator = const PushFoldEvService()});

  final PushFoldEvService evaluator;

  Future<List<TrainingPackSpot>> generateMissing(
    TrainingPackTemplate template, {
    void Function(double progress)? onProgress,
  }) async {
    final updated = <TrainingPackSpot>[];
    final total = template.spots.length;
    if (total == 0) {
      onProgress?.call(1.0);
      return updated;
    }
    var done = 0;
    var next = 0.1;
    for (final spot in template.spots) {
      final hadEv = spot.heroEv;
      final hadIcm = spot.heroIcmEv;
      if (hadEv == null) {
        await evaluator.evaluate(spot, anteBb: template.anteBb);
      }
      if (hadIcm == null) {
        await evaluator.evaluateIcm(spot, anteBb: template.anteBb);
      }
      if ((hadEv == null && spot.heroEv != null) ||
          (hadIcm == null && spot.heroIcmEv != null)) {
        spot.dirty = true;
        updated.add(spot);
      }
      done++;
      final progress = done / total;
      while (progress >= next && next <= 1) {
        onProgress?.call(next);
        next += 0.1;
      }
    }
    if (next <= 1) onProgress?.call(1.0);
    template.recountCoverage();
    return updated;
  }
}
