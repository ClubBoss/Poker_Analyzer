import 'package:flutter/services.dart' show rootBundle;
import '../core/training/generation/yaml_reader.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../asset_manifest.dart';

/// Loads training pack templates lazily by parsing only metadata initially.
///
/// The full YAML for a pack is fetched and parsed only when explicitly
/// requested via [loadFullPack]. This keeps memory usage low when dealing with
/// large libraries containing thousands of spots.
class LazyPackLoaderService {
  LazyPackLoaderService._();

  static final instance = LazyPackLoaderService._();

  final List<TrainingPackTemplateV2> _metadata = [];
  final Map<String, String> _paths = {};
  final Map<String, TrainingPackTemplateV2> _cache = {};

  /// Loads basic information (id, name, tags, meta) for all packs found in the
  /// asset manifest. Spot details are discarded to avoid large allocations.
  Future<void> preloadMetadata({String path = TrainingPackLibraryV2.packsDir}) async {
    if (_metadata.isNotEmpty) return;
    final manifest = await AssetManifest.instance;
    final reader = const YamlReader();
    final Iterable<String> paths = manifest.keys.where(
      (p) => p.startsWith(path) && p.endsWith('.yaml'),
    );
    for (final p in paths) {
      try {
        final yaml = await rootBundle.loadString(p);
        final map = reader.read(yaml);
        final json = Map<String, dynamic>.from(map);
        json.remove('spots');
        json.remove('dynamicSpots');
        final tpl = TrainingPackTemplateV2.fromJson(json);
        _metadata.add(tpl);
        _paths[tpl.id] = p;
      } catch (_) {}
    }
    _metadata.sort((a, b) => a.name.compareTo(b.name));
  }

  /// Returns all loaded template metadata. Ensure [preloadMetadata] has been
  /// invoked prior to calling this getter.
  List<TrainingPackTemplateV2> get templates => List.unmodifiable(_metadata);

  /// Loads the full template (including spot data) for the given [id].
  /// Results are cached for subsequent calls.
  Future<TrainingPackTemplateV2?> loadFullPack(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final path = _paths[id];
    if (path == null) return null;
    try {
      final tpl = await const YamlReader().loadTemplate(path);
      _cache[id] = tpl;
      return tpl;
    } catch (_) {
      return null;
    }
  }
}

/// Simple engine that streams spots from a loaded [TrainingPackTemplateV2].
/// It keeps a sliding window cache of upcoming spots to minimize pauses during
/// training drills.
class SpotStreamingEngine {
  SpotStreamingEngine(this._template, {this.prefetch = 5})
      : _index = 0,
        _cache = [];

  final TrainingPackTemplateV2 _template;
  final int prefetch;
  final List<TrainingPackSpot> _cache;
  int _index;

  /// Pre-loads the initial set of spots.
  Future<void> initialize() async {
    _cache.addAll(_template.spots.take(prefetch));
  }

  /// Returns the next spot in the sequence and triggers prefetching of
  /// subsequent spots.
  TrainingPackSpot? next() {
    if (_index >= _template.spots.length) return null;
    if (_cache.length < prefetch && _cache.length + _index < _template.spots.length) {
      final remaining = _template.spots.skip(_index + _cache.length).take(prefetch - _cache.length);
      _cache.addAll(remaining);
    }
    final spot = _cache.removeAt(0);
    _index++;
    return spot;
  }
}
