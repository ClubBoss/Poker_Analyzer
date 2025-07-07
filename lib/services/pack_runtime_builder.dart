import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_variant.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../models/game_type.dart';
import '../core/error_logger.dart';
import 'pack_generator_service.dart';
import 'range_library_service.dart';

class PackRuntimeBuilder {
  const PackRuntimeBuilder();

  Future<List<TrainingPackSpot>> generateFromVariant(
    TrainingPackTemplate tpl,
    TrainingPackVariant variant,
  ) async {
    var range = <String>[];
    if (variant.rangeId != null) {
      range = await RangeLibraryService.instance.getRange(variant.rangeId!);
    }
    if (range.isEmpty) {
      range = tpl.heroRange ??
          PackGeneratorService.topNHands(25).toList();
    }
    if (range.isEmpty) {
      ErrorLogger.instance.logError('No range for ${variant.rangeId}');
      return [];
    }
    final pos = variant.position == HeroPosition.unknown
        ? tpl.heroPos
        : variant.position;
    switch (variant.gameType) {
      case GameType.tournament:
        final tplGen = PackGeneratorService.generatePushFoldPackSync(
          id: '${tpl.id}_${variant.rangeId ?? 'default'}',
          name: tpl.name,
          heroBbStack: tpl.heroBbStack,
          playerStacksBb: tpl.playerStacksBb,
          heroPos: pos,
          heroRange: range,
          bbCallPct: tpl.bbCallPct,
          anteBb: tpl.anteBb,
        );
        return tplGen.spots.take(tpl.spotCount).toList();
      default:
        throw UnimplementedError('Generator for ${variant.gameType}');
    }
  }
}
