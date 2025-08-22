import '../models/skill_tree.dart';
import '../models/skill_tree_node_model.dart';
import 'skill_tree_builder_service.dart';
import 'skill_tree_library_service.dart';
import 'skill_tree_node_progress_tracker.dart';
import 'skill_tree_final_node_completion_detector.dart';
import 'skill_tree_unlock_evaluator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'track_milestone_unlocker_service.dart';

/// Progress information for a single skill tree track.
class TrackProgressEntry {
  final SkillTree tree;
  final double completionRate; // 0.0 to 1.0
  final bool isCompleted;

  TrackProgressEntry({
    required this.tree,
    required this.completionRate,
    required this.isCompleted,
  });
}

/// Provides aggregated progress across all skill tree tracks.
class SkillTreeTrackProgressService {
  final SkillTreeLibraryService library;
  final SkillTreeNodeProgressTracker progress;
  final SkillTreeFinalNodeCompletionDetector detector;

  SkillTreeTrackProgressService({
    SkillTreeLibraryService? library,
    SkillTreeNodeProgressTracker? progress,
    SkillTreeFinalNodeCompletionDetector? detector,
  }) : library = library ?? SkillTreeLibraryService.instance,
       progress = progress ?? SkillTreeNodeProgressTracker.instance,
       detector = detector ?? SkillTreeFinalNodeCompletionDetector();

  Future<void> _ensureLoaded() async {
    if (library.getAllNodes().isEmpty) {
      await library.reload();
    }
    await progress.isCompleted('');
  }

  Future<List<TrackProgressEntry>> getAllTrackProgress() async {
    await _ensureLoaded();
    final nodes = library.getAllNodes();
    final byCategory = <String, List<SkillTreeNodeModel>>{};
    for (final n in nodes) {
      byCategory.putIfAbsent(n.category, () => []).add(n);
    }

    final builder = const SkillTreeBuilderService();
    final results = <TrackProgressEntry>[];
    final categories = byCategory.keys.toList()..sort();
    for (final cat in categories) {
      final tree =
          library.getTree(cat)?.tree ??
          builder.build(byCategory[cat]!, category: cat).tree;
      final compIds = progress.completedNodeIds.value;
      var total = 0;
      var done = 0;
      for (final node in tree.nodes.values) {
        final opt = (node as dynamic).isOptional == true;
        if (opt) continue;
        total++;
        if (compIds.contains(node.id)) done++;
      }
      final rate = total > 0 ? done / total : 0.0;
      final complete = await detector.isTreeCompleted(tree);
      results.add(
        TrackProgressEntry(
          tree: tree,
          completionRate: rate,
          isCompleted: complete,
        ),
      );
    }
    return results;
  }

  Future<TrackProgressEntry?> getCurrentTrack() async {
    final all = await getAllTrackProgress();
    for (final entry in all) {
      if (!entry.isCompleted) return entry;
    }
    return all.isEmpty ? null : all.last;
  }

  Future<TrackProgressEntry?> getNextTrack() async {
    final all = await getAllTrackProgress();
    for (var i = 0; i < all.length; i++) {
      if (!all[i].isCompleted) {
        return i + 1 < all.length ? all[i + 1] : null;
      }
    }
    return null;
  }

  /// Returns ids of nodes unlocked in [trackId].
  Future<Set<String>> getUnlockedNodeIds(String trackId) async {
    await _ensureLoaded();
    final tree = library.getTrack(trackId)?.tree;
    if (tree == null) return <String>{};
    final evaluator = SkillTreeUnlockEvaluator(progress: progress);
    final unlocked = evaluator.getUnlockedNodes(tree);
    final highestStage = await TrackMilestoneUnlockerService.instance
        .getHighestUnlockedStage(trackId);
    return unlocked
        .where((n) => n.level <= highestStage)
        .map((n) => n.id)
        .toSet();
  }

  /// Returns ids of completed nodes in [trackId].
  Future<Set<String>> getCompletedNodeIds(String trackId) async {
    await _ensureLoaded();
    final tree = library.getTrack(trackId)?.tree;
    if (tree == null) return <String>{};
    final completed = progress.completedNodeIds.value;
    return completed.where(tree.nodes.containsKey).toSet();
  }

  static String _startedKey(String id) => 'skill_track_started_$id';

  /// Marks [trackId] as started.
  Future<void> markStarted(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_startedKey(trackId), true);
  }

  /// Whether [trackId] has been started previously.
  Future<bool> isStarted(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_startedKey(trackId)) ?? false;
  }
}
