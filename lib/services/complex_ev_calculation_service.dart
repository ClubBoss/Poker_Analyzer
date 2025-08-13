import '../helpers/hand_utils.dart';
import '../models/v2/training_pack_spot.dart';
import 'icm_push_ev_service.dart';
import 'push_fold_ev_service.dart';
import 'range_library_service.dart';
import '../models/range_analysis.dart';

class ComplexEVCalculationService {
  ComplexEVCalculationService._();
  static final instance = ComplexEVCalculationService._();

  double calculateIcmEv(TrainingPackSpot spot, {int anteBb = 0}) {
    final hero = spot.hand.heroIndex;
    final code = handCode(spot.hand.heroCards);
    if (code == null) return 0;
    final stack = spot.hand.stacks['$hero']?.round() ?? 0;
    final chipEv = computePushEV(
      heroBbStack: stack,
      bbCount: spot.hand.playerCount - 1,
      heroHand: code,
      anteBb: anteBb,
    );
    final stacks = [
      for (var i = 0; i < spot.hand.playerCount; i++)
        spot.hand.stacks['$i']?.round() ?? 0
    ];
    return computeIcmPushEV(
      chipStacksBb: stacks,
      heroIndex: hero,
      heroHand: code,
      chipPushEv: chipEv,
    );
  }

  Future<RangeAnalysis> analyzeRanges(String heroId, String villainId) async {
    final heroRange = await RangeLibraryService.instance.getRange(heroId);
    final villainRange = await RangeLibraryService.instance.getRange(villainId);
    if (heroRange.isEmpty || villainRange.isEmpty) {
      return const RangeAnalysis(0, 0);
    }
    double hero = 0;
    for (final h in heroRange) {
      hero += computePushEV(
        heroBbStack: 10,
        bbCount: 1,
        heroHand: h,
        anteBb: 0,
      );
    }
    double villain = 0;
    for (final v in villainRange) {
      villain += computePushEV(
        heroBbStack: 10,
        bbCount: 1,
        heroHand: v,
        anteBb: 0,
      );
    }
    return RangeAnalysis(
        hero / heroRange.length, villain / villainRange.length);
  }
}
