import '../models/theory_mini_lesson_node.dart';
import 'theory_lesson_cluster_linker_service.dart';

/// Navigates lessons within their clusters sequentially.
class TheoryLessonNavigatorService {
  final TheoryLessonClusterLinkerService _linker;

  TheoryLessonNavigatorService({TheoryLessonClusterLinkerService? linker})
    : _linker = linker ?? TheoryLessonClusterLinkerService();

  Future<String?> getNextLessonId(String currentLessonId) async {
    final cluster = await _linker.getCluster(currentLessonId);
    if (cluster == null) return null;
    final lessons = List<TheoryMiniLessonNode>.from(cluster.lessons);
    lessons.sort(_compareLessons);
    final index = lessons.indexWhere((l) => l.id == currentLessonId);
    if (index == -1 || index >= lessons.length - 1) return null;
    return lessons[index + 1].id;
  }

  Future<String?> getPreviousLessonId(String currentLessonId) async {
    final cluster = await _linker.getCluster(currentLessonId);
    if (cluster == null) return null;
    final lessons = List<TheoryMiniLessonNode>.from(cluster.lessons);
    lessons.sort(_compareLessons);
    final index = lessons.indexWhere((l) => l.id == currentLessonId);
    if (index <= 0) return null;
    return lessons[index - 1].id;
  }

  static int _compareLessons(TheoryMiniLessonNode a, TheoryMiniLessonNode b) {
    final at = (a.title.isNotEmpty ? a.title : a.id).toLowerCase();
    final bt = (b.title.isNotEmpty ? b.title : b.id).toLowerCase();
    final cmp = at.compareTo(bt);
    if (cmp != 0) return cmp;
    return a.id.compareTo(b.id);
  }
}
