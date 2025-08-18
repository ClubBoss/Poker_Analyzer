import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'training_pack_stats_service.dart';

class TrainingTypeStatsService {
  const TrainingTypeStatsService();

  Future<Map<TrainingType, double>> calculateCompletionPercent(
    List<TrainingPackTemplate> packs,
  ) async {
    final totals = <TrainingType, int>{};
    final completed = <TrainingType, int>{};

    for (final pack in packs) {
      final temp = TrainingPackTemplateV2.fromJson(pack.toJson());
      final type = const TrainingTypeEngine().detectTrainingType(temp);
      final total = pack.spots.isNotEmpty ? pack.spots.length : pack.spotCount;
      if (total == 0) continue;
      totals.update(type, (v) => v + total, ifAbsent: () => total);
      final done = await TrainingPackStatsService.getHandsCompleted(pack.id);
      completed.update(type, (v) => v + done, ifAbsent: () => done);
    }

    final result = <TrainingType, double>{};
    for (final type in TrainingType.values) {
      final tot = totals[type] ?? 0;
      final done = completed[type] ?? 0;
      result[type] = tot > 0 ? (done * 100 / tot).clamp(0, 100).toDouble() : 0;
    }
    return result;
  }
}
