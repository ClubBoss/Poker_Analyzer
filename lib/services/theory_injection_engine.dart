import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';

/// Injects theory spots into a base training pack at a fixed interval.
class TheoryInjectionEngine {
  TheoryInjectionEngine();

  /// Returns [basePack] with theory spots from [theoryPack] inserted.
  ///
  /// The first theory spot is placed at the beginning, then after every
  /// [interval] practice spots from [basePack]. Remaining theory spots are
  /// ignored when the list is exhausted.
  TrainingPackTemplateV2 injectTheory(
    TrainingPackTemplateV2 basePack,
    TrainingPackTemplateV2 theoryPack, {
    int interval = 5,
  }) {
    if (interval <= 0) interval = 1;
    final baseSpots = basePack.spots;
    final theorySpots = theoryPack.spots;
    final merged = <TrainingPackSpot>[];
    var theoryIndex = 0;

    // Start with a theory spot if available.
    if (theorySpots.isNotEmpty) {
      merged.add(theorySpots[theoryIndex]);
      theoryIndex++;
    }

    var count = 0;
    for (final spot in baseSpots) {
      merged.add(spot);
      count++;
      if (count % interval == 0 && theoryIndex < theorySpots.length) {
        merged.add(theorySpots[theoryIndex]);
        theoryIndex++;
      }
    }

    final map = basePack.toJson();
    map['spots'] = [for (final s in merged) s.toJson()];
    map['spotCount'] = merged.length;

    final result = TrainingPackTemplateV2.fromJson(
      Map<String, dynamic>.from(map),
    );
    result.isGeneratedPack = basePack.isGeneratedPack;
    result.isSampledPack = basePack.isSampledPack;
    return result;
  }
}
