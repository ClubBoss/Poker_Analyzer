import '../models/v2/training_pack_template.dart';
import 'training_pack_stats_service.dart';
import 'mistake_review_pack_service.dart';
import 'pack_generator_service.dart';

class DynamicPackAdjustmentService {
  final MistakeReviewPackService mistakes;
  const DynamicPackAdjustmentService({required this.mistakes});

  Future<TrainingPackTemplate> adjust(TrainingPackTemplate tpl) async {
    final stat = await TrainingPackStatsService.getStats(tpl.id);
    var diff = 0;
    if (stat != null) {
      if (stat.accuracy > 0.85 && stat.postEvPct >= stat.preEvPct) diff++;
      if (stat.accuracy < 0.6 || stat.postEvPct < stat.preEvPct) diff--;
    }
    final mc = mistakes.mistakeCount(tpl.id);
    if (mc > 5) diff--;
    var stack = (tpl.heroBbStack + diff).clamp(5, 40);
    final base = tpl.heroRange ?? PackGeneratorService.topNHands(25).toList();
    var pct = (base.length * 100 / 169).round() + diff * 5;
    pct = pct.clamp(5, 100);
    final range = PackGeneratorService.topNHands(pct).toList();
    return tpl.copyWith(heroBbStack: stack, heroRange: range);
  }
}
