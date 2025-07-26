import 'package:flutter/services.dart' show rootBundle;

import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/theory_pack_model.dart';

/// Loads and indexes theory packs stored as YAML files.
class TheoryPackLibraryService {
  TheoryPackLibraryService._();

  /// Singleton instance of this service.
  static final TheoryPackLibraryService instance = TheoryPackLibraryService._();

  /// Default directory with bundled theory packs.
  static const String _dir = 'assets/theory_packs/';

  final List<TheoryPackModel> _packs = [];
  final Map<String, TheoryPackModel> _index = {};

  /// Unmodifiable list of all loaded packs.
  List<TheoryPackModel> get all => List.unmodifiable(_packs);

  /// Returns a pack with [id] if loaded.
  TheoryPackModel? getById(String id) => _index[id];

  /// Clears current state.
  void _clear() {
    _packs.clear();
    _index.clear();
  }

  /// Loads all theory packs from assets.
  Future<void> loadAll() async {
    if (_packs.isNotEmpty) return;
    await reload();
  }

  /// Reloads theory packs from assets.
  Future<void> reload() async {
    _clear();
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((p) => p.startsWith(_dir) && p.endsWith('.yaml'))
        .toList();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        var id = map['id']?.toString() ?? '';
        if (id.isEmpty) {
          final name = path.split('/').last;
          id = name.replaceAll('.yaml', '');
        }
        final title = map['title']?.toString() ?? '';
        final secYaml = map['sections'];
        final sections = <TheorySectionModel>[];
        if (secYaml is List) {
          for (final s in secYaml) {
            if (s is Map) {
              sections.add(
                TheorySectionModel.fromYaml(Map<String, dynamic>.from(s)),
              );
            }
          }
        }
        final pack = TheoryPackModel(id: id, title: title, sections: sections);
        _packs.add(pack);
        _index[id] = pack;
      } catch (_) {}
    }
  }
}
