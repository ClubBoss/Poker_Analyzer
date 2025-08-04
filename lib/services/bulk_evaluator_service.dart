import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import 'offline_evaluator_service.dart';
import '../utils/template_coverage_utils.dart';

class BulkEvaluatorService {
  BulkEvaluatorService({OfflineEvaluatorService? evaluator})
      : evaluator = evaluator ?? OfflineEvaluatorService();

  final OfflineEvaluatorService evaluator;

  Future<List<TrainingPackSpot>> generateMissing(
    dynamic target, {
    void Function(double progress)? onProgress,
    int anteBb = 0,
  }) async {
    if (target is TrainingPackTemplate) {
      final template = target;
      final updated = <TrainingPackSpot>[];
      final spots = template.spots;
      final total = spots.length;
      if (total == 0) {
        onProgress?.call(1.0);
        return updated;
      }
      var done = 0;
      var next = 0.1;
      for (final spot in spots) {
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
      TemplateCoverageUtils.recountAll(template).applyTo(template.meta);
      return updated;
    } else if (target is TrainingPackSpot) {
      final spot = target;
      final hadEv = spot.heroEv;
      final hadIcm = spot.heroIcmEv;
      if (hadEv == null) {
        await evaluator.evaluate(spot, anteBb: anteBb);
      }
      if (hadIcm == null) {
        await evaluator.evaluateIcm(spot, anteBb: anteBb);
      }
      onProgress?.call(1.0);
      if ((hadEv == null && spot.heroEv != null) ||
          (hadIcm == null && spot.heroIcmEv != null)) {
        return [spot];
      }
      return [];
    }
    return [];
  }

  Future<int> generateMissingForTemplate(
    TrainingPackTemplate template, {
    void Function(double progress)? onProgress,
  }) async {
    final res = await generateMissing(template, onProgress: onProgress);
    return res.length;
  }

  int countMissing(TrainingPackTemplate template) {
    return template.spots
        .where((s) => s.heroEv == null || s.heroIcmEv == null)
        .length;
  }
}
