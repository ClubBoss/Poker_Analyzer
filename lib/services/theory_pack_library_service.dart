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

  /// Embedded starter theory packs shipped with the app.
  static const List<Map<String, dynamic>> _defaultPackData = [
    {
      'id': 'push_fold_basics',
      'title': 'Push/Fold Basics',
      'tags': ['starter'],
      'sections': [
        {
          'title': 'When to push',
          'text':
              'Short stack play revolves around pushing all-in when under 15BBs.',
          'type': 'info',
        },
        {
          'title': 'Ranges',
          'text': 'Push widest from BTN and SB, tighten in early positions.',
          'type': 'tip',
        },
      ],
    },
    {
      'id': 'icm_essentials',
      'title': 'ICM Essentials',
      'tags': ['starter', 'icm'],
      'sections': [
        {
          'title': 'What is ICM',
          'text': 'ICM evaluates chip value based on payout structure.',
          'type': 'info',
        },
        {
          'title': 'Bubble play',
          'text': 'Near the money bubble tighten your calling ranges.',
          'type': 'tip',
        },
      ],
    },
    {
      'id': 'tournament_tips',
      'title': 'Tournament Tips',
      'tags': ['starter'],
      'sections': [
        {
          'title': 'Before you play',
          'text': 'Get rest, review ranges and plan your session.',
          'type': 'info',
        },
        {
          'title': 'During breaks',
          'text': 'Check big hands quickly and stay hydrated.',
          'type': 'tip',
        },
      ],
    },
  ];

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
    await loadDefaultPacks();
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
        final tagYaml = map['tags'];
        final tags = <String>[];
        if (tagYaml is List) {
          for (final t in tagYaml) {
            tags.add(t.toString());
          }
        }
        final pack = TheoryPackModel(
          id: id,
          title: title,
          sections: sections,
          tags: tags,
        );
        _packs.add(pack);
        _index[id] = pack;
      } catch (_) {}
    }
    await loadDefaultPacks();
  }

  /// Adds embedded starter packs to the library if not already present.
  Future<void> loadDefaultPacks() async {
    for (final data in _defaultPackData) {
      final id = data['id']?.toString() ?? '';
      if (id.isEmpty || _index.containsKey(id)) continue;
      final pack = TheoryPackModel.fromYaml(data);
      _packs.add(pack);
      _index[id] = pack;
    }
  }
}
