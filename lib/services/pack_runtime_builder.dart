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

  static final _cache = <String, List<TrainingPackSpot>>{};
  static final _pending = <String, Future<List<TrainingPackSpot>>>{};

  static String _key(TrainingPackTemplate tpl, TrainingPackVariant v) =>
      '${tpl.id}_${v.gameType.name}_${v.position.name}_${v.rangeId ?? 'default'}';

  Future<List<TrainingPackSpot>> buildIfNeeded(
    TrainingPackTemplate tpl,
    TrainingPackVariant variant,
  ) async {
    final key = _key(tpl, variant);
    final cached = _cache[key];
    if (cached != null) return cached;
    final pending = _pending[key];
    if (pending != null) return pending;
    final future = _generateSafe(tpl, variant, key);
    _pending[key] = future;
    return future.whenComplete(() => _pending.remove(key));
  }

  void clearCache(
    TrainingPackTemplate tpl,
    TrainingPackVariant variant,
  ) {
    final key = _key(tpl, variant);
    _cache.remove(key);
    _pending.remove(key);
  }

  bool isPending(TrainingPackTemplate tpl, TrainingPackVariant variant) {
    final key = _key(tpl, variant);
    return _pending.containsKey(key);
  }

  Future<List<TrainingPackSpot>> _generateSafe(
    TrainingPackTemplate tpl,
    TrainingPackVariant variant,
    String key,
  ) async {
    try {
      final spots = await generateFromVariant(tpl, variant);
      _cache[key] = spots;
      return spots;
    } catch (e, st) {
      ErrorLogger.instance.logError('Build variant failed', e, st);
      return [];
    }
  }

  Future<List<TrainingPackSpot>> generateFromVariant(
    TrainingPackTemplate tpl,
    TrainingPackVariant variant,
  ) async {
    var range = <String>[];
    if (variant.rangeId != null) {
      range = await RangeLibraryService.instance.getRange(variant.rangeId!);
    }
    if (range.isEmpty) {
      range = tpl.heroRange ?? PackGeneratorService.topNHands(25).toList();
    }
    if (range.isEmpty) {
      ErrorLogger.instance.logError('No range for ${variant.rangeId}');
      return [];
    }
    final pos = variant.position == HeroPosition.unknown
        ? tpl.heroPos
        : variant.position;
    List<TrainingPackSpot> spots;
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
        spots = tplGen.spots;
        break;
      default:
        throw UnimplementedError('Generator for ${variant.gameType}');
    }
    return spots.take(tpl.spotCount).toList();
  }
}
