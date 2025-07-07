import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_variant.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/game_type.dart';
import 'pack_generator_service.dart';
import 'range_library_service.dart';

class PackRuntimeBuilder {
  const PackRuntimeBuilder();

  Future<List<TrainingPackSpot>> generateFromVariant(
    TrainingPackTemplate tpl,
    TrainingPackVariant variant,
  ) async {
    final range = variant.rangeId != null
        ? await RangeLibraryService.instance.getRange(variant.rangeId!)
        : <String>[];
    if (variant.gameType == GameType.tournament) {
      return PackGeneratorService.autoGenerateSpots(
        id: tpl.id,
        stack: tpl.heroBbStack,
        players: tpl.playerStacksBb,
        pos: variant.position,
        count: tpl.spotCount,
        bbCallPct: tpl.bbCallPct,
        anteBb: tpl.anteBb,
        range: range.isEmpty ? null : range,
      );
    }
    return PackGeneratorService.autoGenerateSpots(
      id: tpl.id,
      stack: tpl.heroBbStack,
      players: tpl.playerStacksBb,
      pos: variant.position,
      count: tpl.spotCount,
      bbCallPct: tpl.bbCallPct,
      anteBb: tpl.anteBb,
      range: range.isEmpty ? null : range,
    );
  }
}
