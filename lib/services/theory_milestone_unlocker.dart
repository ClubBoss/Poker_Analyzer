import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../models/theory_cluster_summary.dart';
import '../models/theory_mini_lesson_node.dart';
import 'theory_lesson_progress_tracker.dart';

class TheoryMilestoneEvent {
  final String clusterName;
  final double progress;
  final String type;

  const TheoryMilestoneEvent({
    required this.clusterName,
    required this.progress,
    required this.type,
  });
}

class TheoryMilestoneUnlocker {
  final TheoryLessonProgressTracker tracker;
  static const _prefsPrefix = 'theory_milestone_';
  static const List<double> thresholds = [0.25, 0.5, 1.0];

  final StreamController<TheoryMilestoneEvent> _ctrl =
      StreamController<TheoryMilestoneEvent>.broadcast();

  TheoryMilestoneUnlocker({TheoryLessonProgressTracker? tracker})
      : tracker = tracker ?? const TheoryLessonProgressTracker();

  Stream<TheoryMilestoneEvent> get stream => _ctrl.stream;

  Future<int> _loadIndex(String cluster) async {
    final prefs = await PreferencesService.getInstance();
    return prefs.getInt('$_prefsPrefix$cluster') ?? -1;
  }

  Future<void> _saveIndex(String cluster, int index) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setInt('$_prefsPrefix$cluster', index);
  }

  Future<void> checkCluster({
    required String clusterName,
    required TheoryClusterSummary summary,
    required Map<String, TheoryMiniLessonNode> allLessons,
  }) async {
    final progress =
        await tracker.progressForCluster(summary, allLessons);
    final prevIndex = await _loadIndex(clusterName);
    var newIndex = prevIndex;
    for (var i = thresholds.length - 1; i >= 0; i--) {
      if (progress >= thresholds[i]) {
        newIndex = i;
        break;
      }
    }
    if (newIndex > prevIndex) {
      await _saveIndex(clusterName, newIndex);
      final double t = thresholds[newIndex];
      final String type;
      if (t == 1.0) {
        type = 'unlock';
      } else if (t == 0.5) {
        type = 'badge';
      } else {
        type = 'insight';
      }
      _ctrl.add(
        TheoryMilestoneEvent(
          clusterName: clusterName,
          progress: progress,
          type: type,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await _ctrl.close();
  }

  Future<void> reset() async {
    final prefs = await PreferencesService.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefsPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
