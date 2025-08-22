import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_stats_service.dart';

class TrainingPathUnlockService {
  TrainingPathUnlockService();

  /// Returns the subset of [allPacks] that are unlocked based on [stats].
  ///
  /// [stats] is a map of pack id to [TrainingPackStat] containing the player's
  /// performance data.
  List<TrainingPackTemplateV2> getUnlocked(
    List<TrainingPackTemplateV2> allPacks,
    Map<String, TrainingPackStat> stats,
  ) {
    final unlocked = <TrainingPackTemplateV2>[];
    for (final pack in allPacks) {
      final rules = pack.unlockRules;
      if (rules == null) {
        unlocked.add(pack);
        continue;
      }
      var allow = true;
      final stat = stats[pack.id];

      if (rules.requiredPacks.isNotEmpty) {
        for (final req in rules.requiredPacks) {
          if (!stats.containsKey(req)) {
            allow = false;
            break;
          }
        }
      }

      if (allow && rules.minAccuracy != null) {
        final acc = stat?.accuracy ?? 0.0;
        if (acc < rules.minAccuracy!) allow = false;
      }

      if (allow && rules.minEV != null) {
        final ev = stat?.postEvPct > 0
            ? stat!.postEvPct
            : stat?.preEvPct ?? 0.0;
        if (ev < rules.minEV!) allow = false;
      }

      if (allow && rules.minIcm != null) {
        final icm = stat?.postIcmPct > 0
            ? stat!.postIcmPct
            : stat?.preIcmPct ?? 0.0;
        if (icm < rules.minIcm!) allow = false;
      }

      if (allow) {
        unlocked.add(pack);
      }
    }
    return unlocked;
  }
}
