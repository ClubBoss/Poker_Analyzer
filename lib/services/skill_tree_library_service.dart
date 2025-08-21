import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../asset_manifest.dart';
import '../models/skill_tree_node_model.dart';
import '../models/skill_tree_build_result.dart';
import 'skill_tree_builder_service.dart';

/// Loads skill tree node definitions from YAML assets and exposes built trees.
class SkillTreeLibraryService {
  SkillTreeLibraryService._();

  static final instance = SkillTreeLibraryService._();

  static const _dir = 'assets/skills/cash/';

  final _builder = const SkillTreeBuilderService();

  final Map<String, SkillTreeBuildResult> _trees = {};
  final List<SkillTreeNodeModel> _nodes = [];

  /// Loads all skill tree YAML files from the assets directory.
  Future<void> reload() async {
    _trees.clear();
    _nodes.clear();
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((p) => p.startsWith(_dir) && p.endsWith('.yaml'))
        .toList()
      ..sort();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final doc = loadYaml(raw);
        if (doc is List) {
          final nodes = <SkillTreeNodeModel>[];
          for (final item in doc) {
            if (item is Map) {
              try {
                final node = SkillTreeNodeModel.fromYaml(
                  Map<String, dynamic>.from(item),
                );
                if (node.id.isEmpty) continue;
                nodes.add(node);
              } catch (_) {}
            }
          }
          if (nodes.isNotEmpty) {
            final res = _builder.build(nodes);
            final category = nodes.first.category;
            _trees[category] = res;
            _nodes.addAll(nodes);
          }
        }
      } catch (_) {}
    }
  }

  /// Returns the skill tree for [category], or `null` if not found.
  SkillTreeBuildResult? getTree(String category) => _trees[category];

  /// Returns the skill track for [trackId].
  ///
  /// This is an alias for [getTree] to allow referencing tracks by id.
  SkillTreeBuildResult? getTrack(String trackId) => getTree(trackId);

  /// Returns all loaded skill tree tracks in no particular order.
  List<SkillTreeBuildResult> getAllTracks() => List.unmodifiable(_trees.values);

  /// Returns all loaded nodes across categories in insertion order.
  List<SkillTreeNodeModel> getAllNodes() => List.unmodifiable(_nodes);
}
