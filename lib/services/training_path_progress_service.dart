import 'package:flutter/services.dart' show rootBundle;
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:yaml/yaml.dart';

class TrainingPathProgressService {
  TrainingPathProgressService._();
  static final instance = TrainingPathProgressService._();

  static const _prefsPrefix = 'training_path_completed_';
  static const _assetPath = 'assets/training_paths.yaml';

  Map<String, List<String>>? _cache;

  Future<Map<String, List<String>>> _loadStages() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final map = loadYaml(raw) as Map;
      final result = <String, List<String>>{};
      map.forEach((key, value) {
        if (key is String && value is Map && value['packs'] is List) {
          result[key] = [for (final v in value['packs']) v.toString()];
        } else if (key is String && value is List) {
          result[key] = [for (final v in value) v.toString()];
        }
      });
      _cache = result;
      return result;
    } catch (_) {
      _cache = <String, List<String>>{};
      return _cache!;
    }
  }

  /// Returns map of stage id to pack ids as defined in the YAML asset.
  Future<Map<String, List<String>>> getStages() => _loadStages();

  Future<void> markCompleted(String packId) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool('$_prefsPrefix$packId', true);
  }

  Future<double> getProgressInStage(String stageId) async {
    final stages = await _loadStages();
    final packs = stages[stageId] ?? const <String>[];
    if (packs.isEmpty) return 0.0;
    final prefs = await PreferencesService.getInstance();
    final completed =
        packs.where((id) => prefs.getBool('$_prefsPrefix$id') ?? false).length;
    return completed / packs.length;
  }

  Future<List<String>> getCompletedPacksInStage(String stageId) async {
    final stages = await _loadStages();
    final packs = stages[stageId] ?? const <String>[];
    if (packs.isEmpty) return const <String>[];
    final prefs = await PreferencesService.getInstance();
    final done = <String>[];
    for (final id in packs) {
      if (prefs.getBool('$_prefsPrefix$id') ?? false) {
        done.add(id);
      }
    }
    return done;
  }
}
