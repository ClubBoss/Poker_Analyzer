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
      if (progress >= next || done == total) {
        onProgress?.call(progress.clamp(0, 1));
        next += 0.1;
      }
    }
    template.recountCoverage();
    return updated;
  }
}
