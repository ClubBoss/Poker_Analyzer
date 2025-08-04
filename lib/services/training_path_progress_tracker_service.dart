import 'package:shared_preferences/shared_preferences.dart';

import 'training_path_node_definition_service.dart';

/// Tracks completion status for training path nodes and computes which
/// nodes are currently unlocked based on prerequisites.
class TrainingPathProgressTrackerService {
  static const _prefsKey = 'training_path_completed_nodes';

  final TrainingPathNodeDefinitionService definitions;
  final SharedPreferences? _prefsOverride;

  const TrainingPathProgressTrackerService({
    this.definitions = const TrainingPathNodeDefinitionService(),
    SharedPreferences? prefs,
  }) : _prefsOverride = prefs;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  /// Marks the given [nodeId] as completed and persists the change.
  Future<void> markCompleted(String nodeId) async {
    final prefs = await _prefs;
    final current = prefs.getStringList(_prefsKey) ?? <String>[];
    if (!current.contains(nodeId)) {
      current.add(nodeId);
      await prefs.setStringList(_prefsKey, current);
    }
  }

  /// Returns the set of completed node IDs.
  Future<Set<String>> getCompletedNodeIds() async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    return list.toSet();
  }

  /// Computes the set of unlocked node IDs based on prerequisites.
  ///
  /// A node is unlocked if all of its prerequisites have been completed.
  Future<Set<String>> getUnlockedNodeIds() async {
    final completed = await getCompletedNodeIds();
    final nodes = definitions.getPath();
    final unlocked = <String>{};
    for (final node in nodes) {
      if (node.prerequisiteNodeIds.every(completed.contains)) {
        unlocked.add(node.id);
      }
    }
    return unlocked;
  }
}
