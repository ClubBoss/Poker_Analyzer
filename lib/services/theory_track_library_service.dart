import 'package:flutter/services.dart' show rootBundle;
import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/theory_track_model.dart';
import '../models/theory_block_model.dart';

/// Loads and indexes theory tracks from bundled YAML files.
class TheoryTrackLibraryService {
  TheoryTrackLibraryService._();
  static final TheoryTrackLibraryService instance =
      TheoryTrackLibraryService._();

  static const String _trackDir = 'assets/theory_tracks/';
  static const String _blockDir = 'assets/theory_blocks/';

  final List<TheoryTrackModel> _tracks = [];
  final Map<String, TheoryTrackModel> _index = {};

  List<TheoryTrackModel> get all => List.unmodifiable(_tracks);

  Future<void> loadAll() async {
    if (_tracks.isNotEmpty) return;
    await reload();
  }

  Future<void> reload() async {
    _tracks.clear();
    _index.clear();
    final manifest = await AssetManifest.instance;
    final trackPaths = manifest.keys
        .where((p) => p.startsWith(_trackDir) && p.endsWith('.yaml'))
        .toList();
    for (final path in trackPaths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        final id =
            map['id']?.toString() ??
            path.split('/').last.replaceAll('.yaml', '');
        final title = map['title']?.toString() ?? '';
        final blockYaml = map['blocks'];
        final blockIds = <String>[];
        if (blockYaml is List) {
          for (final b in blockYaml) {
            blockIds.add(b.toString());
          }
        }
        final blocks = <TheoryBlockModel>[];
        for (final bid in blockIds) {
          try {
            final bRaw = await rootBundle.loadString('$_blockDir$bid.yaml');
            final bMap = const YamlReader().read(bRaw);
            blocks.add(
              TheoryBlockModel.fromYaml(Map<String, dynamic>.from(bMap)),
            );
          } catch (_) {}
        }
        final track = TheoryTrackModel(id: id, title: title, blocks: blocks);
        _tracks.add(track);
        _index[id] = track;
      } catch (_) {}
    }
  }

  TheoryTrackModel? getById(String id) => _index[id];
}
