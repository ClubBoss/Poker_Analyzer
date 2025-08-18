import 'package:flutter/services.dart' show rootBundle;
import '../../generation/yaml_reader.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/game_type.dart';
import '../engine/training_type_engine.dart';
import '../../../asset_manifest.dart';
import '../../../models/v2/pack_ux_metadata.dart';

class TrainingPackLibraryV2 {
  static const packsDir = 'assets/packs/v2/';
  static const mvpPacksDir = 'assets/training_packs/';
  static const mvpPackId = 'push_fold_mvp';

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
    Iterable<String> paths = manifest.keys.where(
      (p) => p.startsWith(path) && p.endsWith('.yaml'),
    );
    if (path == packsDir) {
      final extra = manifest.keys.where(
        (p) => p.startsWith(mvpPacksDir) && p.endsWith('.yaml'),
      );
      paths = [...paths, ...extra];
    }
    if (paths.isEmpty) return;
    clear();
    for (final p in paths) {
      try {
        final yaml = await rootBundle.loadString(p);
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final version = tpl.meta['schemaVersion']?.toString();
        if (version == null || version.startsWith('2.')) {
          addPack(tpl);
        }
      } catch (_) {}
    }
    _packs.sort((a, b) {
      if (a.id == mvpPackId) return -1;
      if (b.id == mvpPackId) return 1;
      return a.name.compareTo(b.name);
    });
  }

  Future<void> reload() => loadFromFolder();

  List<TrainingPackTemplateV2> filterBy({
    GameType? gameType,
    TrainingType? type,
    List<String>? tags,
    List<String>? themes,
    TrainingPackLevel? level,
    String? goal,
  }) {
    final goalStr = goal?.trim().toLowerCase();
    final themeSet = themes?.map((e) => e.trim().toLowerCase()).toSet();
    return [
      for (final p in _packs)
        if ((gameType == null || p.gameType == gameType) &&
            (type == null || p.trainingType == type) &&
            (tags == null || tags.every((t) => p.tags.contains(t))) &&
            (themeSet == null || _themeMatches(p, themeSet)) &&
            (level == null || p.meta['level']?.toString() == level.name) &&
            (goalStr == null ||
                ((p.goal.isNotEmpty ? p.goal : p.meta['goal']?.toString() ?? '')
                        .trim()
                        .toLowerCase() ==
                    goalStr)))
          p,
    ];
  }

  bool _themeMatches(TrainingPackTemplateV2 p, Set<String> themes) {
    final raw = p.meta['theme'];
    final set = <String>{};
    if (raw is String) {
      set.add(raw.trim().toLowerCase());
    } else if (raw is List) {
      for (final t in raw) {
        set.add(t.toString().trim().toLowerCase());
      }
    }
    if (set.isEmpty) return false;
    return set.intersection(themes).isNotEmpty;
  }

  TrainingPackTemplateV2? getById(String id) => _index[id];
}
