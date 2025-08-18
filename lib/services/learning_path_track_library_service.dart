import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../asset_manifest.dart';
import '../models/learning_path_track_model.dart';

class LearningPathTrackLibraryService {
  LearningPathTrackLibraryService._();

  static final instance = LearningPathTrackLibraryService._();

  static const _dir = 'assets/learning_tracks/';

  final List<LearningPathTrackModel> _tracks = [];
  final Map<String, LearningPathTrackModel> _index = {};

  Future<void> reload() async {
    _tracks.clear();
    _index.clear();
    final manifest = await AssetManifest.instance;
    final paths =
        manifest.keys
            .where((p) => p.startsWith(_dir) && p.endsWith('.yaml'))
            .toList()
          ..sort();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final yaml = loadYaml(raw);
        if (yaml is Map) {
          final model = LearningPathTrackModel.fromYaml(
            Map<String, dynamic>.from(yaml),
          );
          _tracks.add(model);
          _index[model.id] = model;
        }
      } catch (_) {}
    }
    _tracks.sort((a, b) => a.order.compareTo(b.order));
  }

  List<LearningPathTrackModel> get tracks => List.unmodifiable(_tracks);

  LearningPathTrackModel? getById(String id) => _index[id];
}
