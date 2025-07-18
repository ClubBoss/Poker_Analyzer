import 'package:flutter/services.dart' show rootBundle;
import '../../generation/yaml_reader.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/game_type.dart';
import '../engine/training_type_engine.dart';
import '../../../asset_manifest.dart';

class TrainingPackLibraryV2 {
  static const packsDir = 'assets/packs/v2/';
  TrainingPackLibraryV2._();
  static final instance = TrainingPackLibraryV2._();

  final List<TrainingPackTemplateV2> _packs = [];
  final Map<String, TrainingPackTemplateV2> _index = {};

  List<TrainingPackTemplateV2> get packs => List.unmodifiable(_packs);

  void clear() {
    _packs.clear();
    _index.clear();
  }

  void addPack(TrainingPackTemplateV2 pack) {
    if (_index.containsKey(pack.id)) return;
    _packs.add(pack);
    _index[pack.id] = pack;
  }

  Future<void> loadFromFolder([String path = packsDir]) async {
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys.where(
      (p) => p.startsWith(path) && p.endsWith('.yaml'),
    );
    if (paths.isEmpty) return;
    clear();
    for (final p in paths) {
      try {
        final yaml = await rootBundle.loadString(p);
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        addPack(tpl);
      } catch (_) {}
    }
  }

  Future<void> reload() => loadFromFolder();

  List<TrainingPackTemplateV2> filterBy({
    GameType? gameType,
    TrainingType? type,
    List<String>? tags,
  }) {
    return [
      for (final p in _packs)
        if ((gameType == null || p.gameType == gameType) &&
            (type == null || p.trainingType == type) &&
            (tags == null || tags.every((t) => p.tags.contains(t))))
          p
    ];
  }

  TrainingPackTemplateV2? getById(String id) => _index[id];
}
