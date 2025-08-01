import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks completion status for skill tree nodes.
class SkillTreeNodeProgressTracker {
  SkillTreeNodeProgressTracker._();
  static final SkillTreeNodeProgressTracker instance =
      SkillTreeNodeProgressTracker._();

  static const String _prefsKey = 'skill_node_progress';

  final ValueNotifier<Set<String>> completedNodeIds =
      ValueNotifier(<String>{});

  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    completedNodeIds.value =
        (prefs.getStringList(_prefsKey)?.toSet() ?? <String>{});
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, completedNodeIds.value.toList());
  }

  /// Whether [nodeId] has been marked as completed.
  Future<bool> isCompleted(String nodeId) async {
    await _load();
    return completedNodeIds.value.contains(nodeId);
  }

  /// Marks [nodeId] as completed and notifies listeners.
  Future<void> markCompleted(String nodeId) async {
    if (nodeId.isEmpty) return;
    await _load();
    final set = completedNodeIds.value;
    if (set.add(nodeId)) {
      completedNodeIds.value = Set<String>.from(set);
      await _save();
    }
  }

  /// Clears stored progress for tests.
  Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    completedNodeIds.value = <String>{};
    _loaded = false;
  }
}
