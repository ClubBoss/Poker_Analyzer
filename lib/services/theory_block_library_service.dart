import 'package:flutter/services.dart' show rootBundle;

import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/theory_block_model.dart';

/// Loads [TheoryBlockModel] definitions from YAML files.
class TheoryBlockLibraryService {
  TheoryBlockLibraryService._();
  static final TheoryBlockLibraryService instance =
      TheoryBlockLibraryService._();

  static const String _dir = 'assets/theory_blocks/';

  final List<TheoryBlockModel> _blocks = [];
  final Map<String, TheoryBlockModel> _byId = {};

  List<TheoryBlockModel> get all => List.unmodifiable(_blocks);
  TheoryBlockModel? getById(String id) => _byId[id];

  Future<void> loadAll() async {
    if (_blocks.isNotEmpty) return;
    await reload();
  }

  Future<void> reload() async {
    _blocks.clear();
    _byId.clear();
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((p) => p.startsWith(_dir) && p.endsWith('.yaml'))
        .toList();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        final block = TheoryBlockModel.fromYaml(Map<String, dynamic>.from(map));
        if (block.id.isEmpty) continue;
        _blocks.add(block);
        _byId[block.id] = block;
      } catch (_) {}
    }
  }
}
