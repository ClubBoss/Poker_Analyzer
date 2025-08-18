import '../models/booster_summary.dart';
import 'theory_booster_effectiveness_service.dart';

class SmartBoosterSummaryEngine {
  final TheoryBoosterEffectivenessService _effectiveness;

  const SmartBoosterSummaryEngine({
    TheoryBoosterEffectivenessService? effectiveness,
  }) : _effectiveness =
           effectiveness ?? TheoryBoosterEffectivenessService.instance;

  Future<BoosterSummary> summarize(String boosterId) async {
    final logs = await _effectiveness.getImpactStats(boosterId);
    if (logs.isEmpty) {
      return BoosterSummary(
        id: boosterId,
        avgDeltaEV: 0.0,
        totalSpots: 0,
        injections: 0,
      );
    }
    double deltaSum = 0.0;
    int spotSum = 0;
    for (final l in logs) {
      deltaSum += l.deltaEV;
      spotSum += l.spotsTracked;
    }
    final injections = logs.length;
    final avg = injections > 0 ? deltaSum / injections : 0.0;
    return BoosterSummary(
      id: boosterId,
      avgDeltaEV: double.parse(avg.toStringAsFixed(4)),
      totalSpots: spotSum,
      injections: injections,
    );
  }

  Future<List<BoosterSummary>> summarizeAll(
    List<String> boosterIds, {
    bool sortByEffectiveness = false,
    bool sortByUsage = false,
  }) async {
    final result = <BoosterSummary>[];
    for (final id in boosterIds) {
      result.add(await summarize(id));
    }
    if (sortByEffectiveness) {
      result.sort((a, b) => b.avgDeltaEV.compareTo(a.avgDeltaEV));
    } else if (sortByUsage) {
      result.sort((a, b) => b.injections.compareTo(a.injections));
    }
    return result;
  }
}
