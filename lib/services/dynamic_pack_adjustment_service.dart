import '../models/v2/training_pack_template.dart';
import 'training_pack_stats_service.dart';
import 'mistake_review_pack_service.dart';
import 'pack_generator_service.dart';
import 'evaluation_executor_service.dart';
import 'saved_hand_manager_service.dart';

class DynamicPackAdjustmentService {
  final MistakeReviewPackService mistakes;
  final EvaluationExecutorService eval;
  final SavedHandManagerService hands;
  const DynamicPackAdjustmentService({
    required this.mistakes,
    required this.eval,
    required this.hands,
  });

  Future<TrainingPackTemplate> adjust(TrainingPackTemplate tpl) async {
    final stat = await TrainingPackStatsService.getStats(tpl.id);
    var diff = 0;
    if (stat != null) {
      if (stat.accuracy > 0.85 && stat.postEvPct >= stat.preEvPct) diff++;
      if (stat.accuracy < 0.6 || stat.postEvPct < stat.preEvPct) diff--;
    }
    final acc = eval.accuracy;
    if (acc > 0.8) diff++;
    if (acc < 0.5) diff--;
    final mc = mistakes.mistakeCount(tpl.id);
    if (mc > 5) diff--;
    final posMist = hands.hands.where((h) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp == null || gto == null || exp == gto) return false;
      final pos = h.heroPosition.toLowerCase();
      if (pos != tpl.heroPos.name) return false;
      final stack = h.stackSizes[h.heroIndex] ?? 0;
      return (stack - tpl.heroBbStack).abs() <= 2;
    }).length;
    if (posMist > 10) diff--;
    var stack = (tpl.heroBbStack + diff).clamp(5, 40);
    final base = tpl.heroRange ?? PackGeneratorService.topNHands(25).toList();
    var pct = (base.length * 100 / 169).round() + diff * 5;
    pct = pct.clamp(5, 100);
    final range = PackGeneratorService.topNHands(pct).toList();
    return tpl.copyWith(heroBbStack: stack, heroRange: range);
  }
}
