import '../models/learning_path_node.dart';
import '../models/theory_lesson_node.dart';
import 'learning_path_graph_orchestrator.dart';
import 'learning_path_node_history.dart';

class SmartWeakReviewPlanner {
  final LearningPathGraphOrchestrator orchestrator;

  SmartWeakReviewPlanner({LearningPathGraphOrchestrator? orchestrator})
      : orchestrator = orchestrator ?? LearningPathGraphOrchestrator();

  static final SmartWeakReviewPlanner instance = SmartWeakReviewPlanner();

  List<LearningPathNode>? _nodes;
  DateTime _lastLoad = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _ensureLoaded() async {
    if (_nodes != null &&
        DateTime.now().difference(_lastLoad) < const Duration(minutes: 5)) {
      return;
    }
    _nodes = await orchestrator.loadGraph();
    _lastLoad = DateTime.now();
  }

  Future<List<String>> getWeakReviewCandidates({
    Duration staleAfter = const Duration(days: 7),
  }) async {
    await _ensureLoaded();
    await LearningPathNodeHistory.instance.load();
    final now = DateTime.now();
    final result = <_Candidate>[];
    for (final n in _nodes ?? <LearningPathNode>[]) {
      if (n is! TheoryLessonNode) continue;
      if (!LearningPathNodeHistory.instance.isCompleted(n.id)) continue;
      final last = LearningPathNodeHistory.instance.lastVisit(n.id);
      if (last == null) continue;
      if (now.difference(last) >= staleAfter) {
        result.add(_Candidate(n.id, last));
      }
    }
    result.sort((a, b) => a.time.compareTo(b.time));
    return [for (final c in result) c.id];
  }
}

class _Candidate {
  final String id;
  final DateTime time;
  const _Candidate(this.id, this.time);
}
