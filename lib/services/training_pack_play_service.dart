import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_variant.dart';
import '../models/v2/training_pack_spot.dart';
import 'pack_runtime_builder.dart';

class TrainingPackPlayService {
  TrainingPackPlayService({PackRuntimeBuilder? builder})
    : _builder = builder ?? const PackRuntimeBuilder();

  final PackRuntimeBuilder _builder;
  String? _lastKey;
  TrainingPackTemplate? _tpl;
  TrainingPackVariant? _variant;
  List<TrainingPackSpot>? _spots;

  Future<List<TrainingPackSpot>> loadSpots(
    TrainingPackTemplate tpl,
    TrainingPackVariant variant, {
    bool forceReload = false,
  }) async {
    final key =
        '${tpl.id}_${variant.gameType.name}_${variant.position.name}_${variant.rangeId ?? 'default'}';
    if (forceReload && _lastKey != null) {
      _builder.clearCache(tpl, variant);
    }
    _tpl = tpl;
    _variant = variant;
    if (!forceReload && key == _lastKey && _spots != null) {
      return _spots!;
    }
    _lastKey = key;
    _spots = await _builder.buildIfNeeded(tpl, variant);
    return _spots!;
  }

  Future<List<TrainingPackSpot>> reload({bool forceReload = false}) async {
    if (_tpl == null || _variant == null) return [];
    return loadSpots(_tpl!, _variant!, forceReload: forceReload);
  }
}
