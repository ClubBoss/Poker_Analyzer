import 'package:collection/collection.dart';
import '../models/v2/training_pack_template.dart';
import '../services/pack_library_loader_service.dart';
import 'training_gap_detector_service.dart';
import 'weak_training_type_detector.dart';
import 'training_type_stats_service.dart';

class TrainingGapNotificationService {
  const TrainingGapNotificationService();

  Future<TrainingPackTemplate?> suggestNextPack({String? excludeId}) async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;

    // Try weak category first
    final weakCategory =
        await const TrainingGapDetectorService().detectWeakCategory();
    if (weakCategory != null) {
      final tpl = library.firstWhereOrNull(
        (t) => t.category == weakCategory && t.id != excludeId,
      );
      if (tpl != null) {
        return TrainingPackTemplate.fromJson(tpl.toJson());
      }
    }

    // Fallback to weakest training type
    final packs = [
      for (final t in library) TrainingPackTemplate.fromJson(t.toJson()),
    ];
    final stats = await const TrainingTypeStatsService()
        .calculateCompletionPercent(packs);
    final weakType = const WeakTrainingTypeDetector().findWeakestType(stats);
    if (weakType != null) {
      final tpl = library.firstWhereOrNull(
        (t) => t.trainingType == weakType && t.id != excludeId,
      );
      if (tpl != null) {
        return TrainingPackTemplate.fromJson(tpl.toJson());
      }
    }
    return null;
  }
}
