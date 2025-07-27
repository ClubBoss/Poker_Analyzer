import 'package:flutter/services.dart' show rootBundle;

import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/theory_track.dart';

/// Loads and manages linear theory lesson tracks from YAML files.
class TheoryTrackEngine {
  TheoryTrackEngine._();
  static final TheoryTrackEngine instance = TheoryTrackEngine._();

  static const String _dir = 'assets/theory_tracks/';

  final List<TheoryTrack> _tracks = [];
  final Map<String, TheoryTrack> _index = {};

  /// Returns all loaded tracks.
  List<TheoryTrack> getAll() => List.unmodifiable(_tracks);

  /// Returns a track by [id] if loaded.
  TheoryTrack? get(String id) => _index[id];

  /// Loads all tracks from assets if not already loaded.
  Future<void> loadAll() async {
    if (_tracks.isNotEmpty) return;
    await reload();
  }

  /// Reloads tracks from assets.
  Future<void> reload() async {
    _tracks.clear();
    _index.clear();
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((p) => p.startsWith(_dir) && p.endsWith('.yaml'))
        .toList();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        final track = TheoryTrack.fromYaml(Map<String, dynamic>.from(map));
        if (track.id.isEmpty) continue;
        _tracks.add(track);
        _index[track.id] = track;
      } catch (_) {}
    }
  }
}
