import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stage_completion_celebration_service.dart';
import 'skill_tree_track_resolver.dart';

/// Tracks completion status for skill tree nodes.
class SkillTreeNodeProgressTracker {
  SkillTreeNodeProgressTracker._();
  static final SkillTreeNodeProgressTracker instance =
      SkillTreeNodeProgressTracker._();

  static const String _prefsKey = 'skill_node_progress';
  static const String _trackPrefsKey = 'completed_tracks';

  final ValueNotifier<Set<String>> completedNodeIds = ValueNotifier(<String>{});
  final ValueNotifier<Set<String>> completedTracks = ValueNotifier(<String>{});

  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    completedNodeIds.value =
        (prefs.getStringList(_prefsKey)?.toSet() ?? <String>{});
    completedTracks.value =
        (prefs.getStringList(_trackPrefsKey)?.toSet() ?? <String>{});
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, completedNodeIds.value.toList());
  }

  Future<void> _saveTracks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_trackPrefsKey, completedTracks.value.toList());
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
      try {
        final trackId = await SkillTreeTrackResolver.instance.getTrackIdForNode(
          nodeId,
        );
        if (trackId != null && trackId.isNotEmpty) {
          await StageCompletionCelebrationService.instance.checkAndCelebrate(
            trackId,
          );
          await StageCompletionCelebrationService.instance
              .checkAndCelebrateTrackCompletion(trackId);
        }
      } catch (_) {}
    }
  }

  /// Whether [trackId] has been marked as fully completed.
  Future<bool> isTrackCompleted(String trackId) async {
    await _load();
    return completedTracks.value.contains(trackId);
  }

  /// Marks [trackId] as fully completed and persists it.
  Future<void> markTrackCompleted(String trackId) async {
    if (trackId.isEmpty) return;
    await _load();
    final set = completedTracks.value;
    if (set.add(trackId)) {
      completedTracks.value = Set<String>.from(set);
      await _saveTracks();
    }
  }

  /// Clears stored progress for tests.
  Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_trackPrefsKey);
    completedNodeIds.value = <String>{};
    completedTracks.value = <String>{};
    _loaded = false;
  }
}
