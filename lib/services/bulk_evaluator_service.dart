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
    final spots = template.spots;
    final updated = <TrainingPackSpot>[];
    final total = spots.length;
    var done = 0;
    var next = 0.1;
    for (final s in spots) {
      final hadEv = s.heroEv;
      final hadIcm = s.heroIcmEv;
      if (hadEv == null) {
        await evaluator.evaluate(s, anteBb: template.anteBb);
      }
      if (hadIcm == null) {
        await evaluator.evaluateIcm(s, anteBb: template.anteBb);
      }
      if ((hadEv == null && s.heroEv != null) ||
          (hadIcm == null && s.heroIcmEv != null)) {
        s.dirty = true;
        updated.add(s);
      }
      done++;
      final progress = done / total;
      if (progress >= next || done == total) {
        onProgress?.call(progress > 1.0 ? 1.0 : progress);
        next += 0.1;
      }
    }
    template.recountCoverage();
    return updated;
  }
}
