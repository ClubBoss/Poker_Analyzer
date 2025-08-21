import 'theory_booster_effectiveness_service.dart';
import '../models/booster_effect_log.dart';

/// Policy engine that decides if a theory booster should be reinjected based on past effectiveness.
class TheoryBoosterReinjectionPolicy {
  final TheoryBoosterEffectivenessService _effectiveness;
  final Set<String> _blocked = <String>{};

  TheoryBoosterReinjectionPolicy({
    TheoryBoosterEffectivenessService? effectiveness,
  }) : _effectiveness =
           effectiveness ?? TheoryBoosterEffectivenessService.instance;

  static final TheoryBoosterReinjectionPolicy instance =
      TheoryBoosterReinjectionPolicy();

  /// Returns `true` if [boosterId] should be reinjected.
  Future<bool> shouldReinject(String boosterId) async {
    if (_blocked.contains(boosterId)) return false;
    final List<BoosterEffectLog> stats = await _effectiveness.getImpactStats(
      boosterId,
    );
    if (stats.isNotEmpty) {
      final BoosterEffectLog last = stats.first;
      if (last.deltaEV < 0.01 || last.spotsTracked < 5) {
        _blocked.add(boosterId);
        return false;
      }
    }
    return true;
  }

  /// Filters [boosterIds] returning only those allowed for reinjection.
  Future<List<String>> getReinjectionCandidates(List<String> boosterIds) async {
    final List<String> result = [];
    for (final String id in boosterIds) {
      if (await shouldReinject(id)) result.add(id);
    }
    return result;
  }
}
